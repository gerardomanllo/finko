# Data model (Firestore)

This document defines **where data lives**, **what fields mean**, and how it ties to [`backend-strategy.md`](backend-strategy.md) (flat ledger + **`monthlyTotals`** with embedded maps). It is a **living** document—extend it when schemas change.

**Real-time aggregates:** Denormalized totals (`monthlyTotals`, `accounts.balanceMinor`, …) stay **incrementally** maintained by **Cloud Functions** on write; clients use **listeners** ([`data-contract.md`](data-contract.md)).

**Scheduled work (allowed):** A **daily** job **only** ingests and stores **foreign-exchange rates** (e.g. from [Frankfurter](https://frankfurter.dev/)) so multi-currency amounts can be converted to the user’s **main currency** for aggregates—**not** for recomputing transaction totals from scratch.

---

## 1. Scope & resolved conventions

| Convention | Detail |
|------------|--------|
| **Tenant** | One Firebase Auth user → one `uid`; user-owned data under `users/{uid}/…`. |
| **Main currency** | User profile **`mainCurrency`** (default **`MXN`**). Aggregates in `monthlyTotals` are stored **in main currency** (minor units) using the **rate for `transactionDate`** (see §10). |
| **Amounts** | **`amountMinor` is always positive** (smallest unit of the **transaction’s** `currency`). **`direction`** distinguishes inflow vs outflow: `in` \| `out` (names may map to income/expense in UI). |
| **Day-only business date** | **`transactionDate`** — `string` **`"yyyy-MM-dd"`**, user-set, **no time** (avoids timezone ambiguity for bucketing). |
| **Bookkeeping time** | **`loadedAt`** — `Timestamp` in **UTC**, when the record was created in the system (no business semantics). |
| **Transfers** | **Two** linked `transactions` documents (one per leg). Shared **`transferGroupId`** (UUID); each doc references **`linkedTransactionId`** (the other leg). |
| **IDs** | `transactions`, legs: auto-ID. `accounts`, `categories`: auto-ID or UUID. `monthlyTotals` doc id: **`yyyy-mm`**. `upcomingTransactions`: auto-ID. |

---

## 2. Top-level map

```
users/{uid}                              # profile + mainCurrency
users/{uid}/transactions/{txId}
users/{uid}/accounts/{accountId}
users/{uid}/categories/{categoryId}
users/{uid}/monthlyTotals/{yyyy-mm}      # aggregates + days (no per-month budgets)
users/{uid}/upcomingTransactions/{id}    # scheduled posts; materialized into transactions
users/{uid}/recurring/{ruleId}           # rules that spawn / link upcoming rows
users/{uid}/_processedAggregateEvents/{eventId}  # idempotency for CF aggregate runs (see §4.1)

forexRates/{yyyy-mm-dd}                  # global daily quotes (see §10)—not user-scoped
```

---

## 3. `users/{uid}` (profile)

| Field | Type | Notes |
|-------|------|--------|
| `displayName` | `string` | |
| `photoUrl` | `string?` | |
| `mainCurrency` | `string` | ISO 4217; default **`MXN`**. |
| `timezone` | `string` | IANA TZ (e.g. `America/Mexico_City`) — **“today”** for `upcomingTransactions` materialization and calendar UX; store on profile, pass to Callable or interpret server-side. |
| `locale` | `string` | BCP 47 tag (e.g. `es-MX`, `en`) — **UI + formatting**; set during onboarding / Settings; see [`language-and-localization.md`](language-and-localization.md). |
| `themePreference` | `string` | `light` \| `dark` \| `system` — persisted from onboarding / Settings. |
| `onboardingCompleted` | `bool` | **`false`** until onboarding **commit** succeeds; then **`true`**. **Gate:** if `true`, **never** show `/onboarding` (including **new device**). |
| `createdAt` | `Timestamp` | UTC. |
| `updatedAt` | `Timestamp` | UTC. |
| `ledgerVersion` | `int` | Optional cache busting. |
| `budgets` | `map<string, object>` | **Recurring monthly targets** (same every month): `categoryId` → `{ "targetMinorMain": int, "kind": "income"|"expense" }`. **Legacy:** flat `categoryId` → minor int coerces to `{ targetMinorMain, kind: expense }` in clients; **`commitOnboarding`** writes canonical rows. |

### 3.1 Integrations (messaging / OTP-linked channels)

Optional. Prefer **one** representation on `users/{uid}` (or move to a subcollection later—avoid duplicating verification state).

**Verification** (OTP success, identifiers): **Callable / Admin SDK only** — clients must not set “verified” flags or trusted identifiers directly. See §11.

| Field | Type | Notes |
|-------|------|-------|
| `integrations` | `map` | Optional; suggested keys below. |

**Suggested shape:**

| Key | Example value | Notes |
|-----|----------------|-------|
| `whatsapp` | `{ "phoneE164": "…", "verifiedAt": Timestamp }` | After server-side OTP. |
| `telegram` | `{ "username": "…", "verifiedAt": Timestamp }` | **OTP** verification flow (product choice: standard UX). |

**Product rule:** At most **one** WhatsApp and **one** Telegram identity per user.

---

## 4. `transactions/{txId}`

**Purpose:** Canonical row for every inflow, outflow, **transfer leg**, or posted item.

| Field | Type | Required | Notes |
|-------|------|----------|--------|
| `transactionDate` | `string` | ✓ | **`"yyyy-MM-dd"`** — user-facing day; drives buckets and FX lookup. |
| `loadedAt` | `Timestamp` | ✓ | UTC; bookkeeping / debugging. |
| `amountMinor` | `int` | ✓ | **> 0**; smallest unit of `currency`. |
| `direction` | `string` | ✓ | `in` \| `out` (map to income/expense UX as needed). |
| `currency` | `string` | ✓ | ISO 4217; may differ from `mainCurrency`. |
| `accountId` | `string` | ✓ | |
| `categoryId` | `string?` | | |
| `type` | `string` | ✓ | `standard`, `transferLeg`, `adjustment`, … |
| `memo` | `string?` | | |
| `transferGroupId` | `string?` | | Same UUID on **both** legs of a transfer. |
| `linkedTransactionId` | `string?` | | Other leg’s `txId`. |
| `sourceUpcomingId` | `string?` | | If created from `upcomingTransactions/{id}` materialization. |
| `amountMinorMain` | `int?` | | **Audit:** amount converted to **main currency** at write time (same basis as aggregates). |
| `fxRateDateUsed` | `string?` | | **`yyyy-mm-dd`** — which **`forexRates`** row was used (after walk-back per §10). |
| `createdAt` | `Timestamp` | ✓ | UTC. |
| `updatedAt` | `Timestamp` | ✓ | UTC. |
| `aggregateApplied` | `bool?` | | **`true`** after Cloud Functions have processed this row for idempotency (see §4.1a). When **`aggregateDeferred`** is **`true`**, balances/`monthlyTotals` are **not** yet updated because **`transactionDate`** is still **after** the user’s calendar today; a scheduled job applies them when the date becomes effective. Omitted or **`false`** (without deferred) means a catch-up apply may still run. **Clients must not set these flags**; restrict in security rules (see §11). |
| `aggregateDeferred` | `bool?` | | **`true`** only from Functions: posting date is in the **future** relative to `users/{uid}.timezone` (or server default); real aggregates run when the client invokes callable **`reconcileDeferredLedgerForUser`** (app open / refresh). Cleared when balances include the row. |
| `reload` / `aggregateReload` | `any?` | | Optional **ops / Functions-only** fields to re-fire the aggregate trigger when money fields are unchanged. **Security rules** forbid client SDK writes on these keys (same as **`aggregateApplied`**); use Admin SDK / backfill if needed. Ignored for “financial equality” checks in Functions. |

**Display rule:** Render `transactionDate` in the user’s **locale**; store **no** wall-clock time on the business date.

**Deletes:** **Hard delete** only—remove the `transactions/{txId}` document when the user deletes a transaction. **Cloud Functions** on delete must **reverse** the same aggregate deltas (and account balances) that an insert/update would have applied. No `deletedAt` / tombstones for MVP.

**Indexes:** Composite indexes listed in **`firestore.indexes.json`** when query shapes are fixed (TBD).

**Writes:** Client writes legs for transfers in one batch when possible. **Cloud Functions** maintain `accounts`, `monthlyTotals` (in **main currency**), etc., and populate **`amountMinorMain`** / **`fxRateDateUsed`** for support and reconciliation.

### 4.1 Idempotency (aggregate `onWrite` triggers)

Cloud Functions may **retry** the same event. Incremental aggregate patches must run **at most once** per logical write.

**Pattern (recommended):**

1. Read **`event.id`** from the Functions runtime (Eventarc / Firestore trigger v2 exposes a stable **event id** per delivery).
2. Before applying deltas to `monthlyTotals` / `accounts`, **`create`** `users/{uid}/_processedAggregateEvents/{eventId}` (e.g. `{ "createdAt": serverTimestamp }`) **only if absent**.
3. If the create fails because the doc already exists → **exit early** (this event was already applied).
4. If create succeeds → apply aggregate logic for this `before`/`after` snapshot.

Alternative or supplement: drive reversals off **document revision** hashes—still keep **event id** as the primary dedupe for duplicate deliveries.

**Deletes:** Use the **delete** event’s `event.id` the same way so reversals are not doubled.

### 4.1a Ledger aggregate trigger (`onLedgerTransactionWritten`)

Implementation lives in **`functions/src/index.ts`** + **`functions/src/aggregateLedger.ts`**. Behavior relevant to operators and client authors:

| Case | Behavior |
|------|----------|
| **Create** | If **`transactionDate` ≤ user today** (`users/{uid}.timezone`, else system default): apply **+1** to **`accounts`** / **`monthlyTotals`**, then **`aggregateApplied: true`** (and clear **`aggregateDeferred`**). If the date is **in the future**: **no** balance/monthly change; set **`aggregateApplied: true`** + **`aggregateDeferred: true`** until the **`reconcileDeferredLedgerForUser`** callable applies them (same idempotency rules). |
| **Delete** | Monetary **−1** only if `snapshotBalancesIncludedThisRow(deleted)` is true: not **`aggregateDeferred`**, and **`aggregateApplied` is not explicitly `false`**. If **`aggregateApplied: false`** (aggregate never succeeded for that doc — any posting date), **no** monetary reverse — otherwise **`accounts`** drift while **`monthlyTotals`** never received the +1. Legacy rows with **`aggregateApplied` omitted** are still reversed (treated as applied). No `aggregateApplied` write on a deleted doc. |
| **Update (money fields changed)** | **−before** only when **before** date is effective and `snapshotBalancesIncludedThisRow(before)` is true; **+after** when after date is effective. On success, merge **`aggregateApplied: true`**; if the resulting row is still future-dated, set **`aggregateDeferred: true`**. |
| **Update (money fields unchanged)** | A pure “diff” would net **zero** (e.g. toggling **`reload`** from Functions only, or other non-financial edits). If **`aggregateApplied` is not `true`** (and not the deferred path), the function runs a **one-shot catch-up**: apply the row as **+1** once when the posting date is effective, then set **`aggregateApplied: true`**. |
| **Update (output-only / meta)** | If only server- or client-meta fields change (see skip list below) and money is unchanged, the trigger may **no-op** after `aggregateApplied` is true—by design. |

**Numeric coercion:** `amountMinor` is coerced to a finite integer in Functions so Firestore/client quirks (string, odd numeric types) do not aggregate as zero.

**Skip list (trigger “audit / meta only” comparison):** when deciding whether an update can be ignored as non-financial noise, the implementation ignores at least: `amountMinorMain`, `fxRateDateUsed`, `updatedAt`, **`aggregateApplied`**, **`aggregateDeferred`**, **`reload`**, **`aggregateReload`**. Financial fields compared for equality include: `transactionDate`, `amountMinor`, `direction`, `currency`, `type`, `accountId`, `categoryId`.

**Deferred reconciliation:** Callable **`reconcileDeferredLedgerForUser`** (HTTPS, signed-in user only) queries `users/{uid}/transactions` where **`aggregateDeferred == true`** and applies rows whose **`transactionDate`** is **≤** user today, using idempotency keys `reconcile-{txId}-{yyyy-mm-dd}`. The Flutter app invokes it at most **once per profile calendar day** (SharedPreferences) on cold start / resume / profile TZ change, and on **every** dashboard/recurring pull-to-refresh (see `DeferredLedgerReconcileService`).

**`monthlyTotals` shape:** `days` is an **embedded map** on the month document (`days["01"]` … `days["31"]`), **not** a subcollection under `monthlyTotals/{yyyy-mm}/`.

---

### 4.2 Net worth vs net cash (definitions)

| Metric | Definition |
|--------|------------|
| **Net worth** | Sum of **all** accounts’ balances (converted to **main currency** for display), using each account’s `balanceMinorMain` (or equivalent). No exclusion flag required unless product later adds “hidden” accounts. |
| **Net cash** | Sum of balances only for accounts that count as **liquid** (e.g. checking, credit cards—per product list), identified by **`includeInNetCash: true`** on `accounts/{accountId}`. |

Charts and cards must label which metric they show. `monthlyTotals.days.*.netWorthEodMinorMain` follows **net worth** unless you split series later.

---

### 4.3 Upcoming scheduled **transfers** (decision: one template)

When a transfer is **posted**, you always create **two** `transactions` (legs). For **scheduled** transfers, Finko uses **one** row in **`upcomingTransactions`** (not two docs per leg).

**Product decision (locked):** **Option A — single template**

- **One** `upcomingTransactions` document with **`kind: "transfer"`**, **`fromAccountId`**, **`toAccountId`**, **`amountMinor`**, optional **`transferGroupId`**.
- On materialization, the Callable creates **two** real **`transactions`** (legs), then **advances** or **deletes** that **single** upcoming doc.
- The **upcoming** UI shows **one line** per scheduled transfer.

**Not used:** storing **two** separate `upcomingTransactions` documents for the same logical transfer (would duplicate list rows unless merged in the query).

---


## 5. `accounts/{accountId}`

**`type` (canonical enum):** Persist **exactly** one of the strings below. **Localized labels** live only in the Flutter **ARB / l10n** layer (mapped from `type`; see [`language-and-localization.md`](language-and-localization.md)).

| Value | Typical English label |
|-------|------------------------|
| `checking` | Checking |
| `savings` | Savings |
| `investment` | Investment |
| `creditCard` | Credit card |
| `loan` | Loan |
| `mortgage` | Mortgage |

| Field | Type | Notes |
|-------|------|--------|
| `name` | `string` | |
| `type` | `string` | One of **`checking`**, **`savings`**, **`investment`**, **`creditCard`**, **`loan`**, **`mortgage`**. |
| `currency` | `string` | ISO 4217 per account. |
| `balanceMinor` | `int` | In **account currency** (denormalized). |
| `balanceMinorMain` | `int?` | Optional denormalized balance in **mainCurrency** for dashboard (maintained by Functions using rates). |
| `includeInNetCash` | `bool` | **Net cash** (liquid) rollup—e.g. checking, credit cards when true. |
| `sortOrder` | `int` | |
| `createdAt` / `updatedAt` | `Timestamp` | UTC. |
| `iconKey` | `string` | UI key into the fixed Material map (default **`account_balance`** if omitted in older rows). |
| `colorArgb` | `int?` | Optional UI tint (ARGB); onboarding writes a palette value. |

**Net worth** sums **all** accounts (§4.2). **Net cash** sums only accounts with **`includeInNetCash`** true.

---

## 6. `categories/{categoryId}`

| Field | Type | Notes |
|-------|------|--------|
| `name` | `string` | |
| `kind` | `string` | `income` \| `expense` |
| `currency` | `string?` | If category is constrained to one currency; else null. |
| `iconKey` | `string` | Key into a **fixed Material icon map** (see [`onboarding.md`](onboarding.md)); stable across platforms. |
| `colorArgb` | `int?` | |
| `sortOrder` | `int` | |

---

## 7. `monthlyTotals/{yyyy-mm}` (denormalized aggregates)

**Purpose:** One document per calendar month: **cashflow aggregates in main currency** and **`days`** for drill-down / charts. **Budget targets** live on **`users/{uid}.budgets`** (not duplicated per month).

| Field | Type | Notes |
|-------|------|--------|
| `yearMonth` | `string` | `2026-04`. |
| `updatedAt` | `Timestamp` | UTC. |
| `incomeMinorMain` | `int` | Month total, **main currency** (minor units). |
| `expenseMinorMain` | `int` | Month total outflows, **main currency**. |
| `byCategoryMinorMain` | `map<string, int>` | `categoryId` → net for month in **main currency**. |
| `days` | `map<string, object>` | Key **`"01"`…`"31"`**. Values: cashflow + optional **`netWorthEodMinorMain`** (see backend-strategy). |

**Legacy:** Older month docs may still contain a **`budgets`** field (ignored by current clients). Prefer **`users/{uid}.budgets`** only going forward.

**Multi-currency:** Functions convert each transaction’s `amountMinor` × **FX rate for `transactionDate`** (see §10) into **main currency** before incrementing these fields.

**Cross-month weeks:** UI sums `days` across **≤2** month docs.

---

## 8. `upcomingTransactions/{id}`

**Purpose:** Each doc is a **scheduled** posting with an **effective** calendar day. **Not** the same as `recurring` rules alone—this is the concrete row the UI lists and the materializer processes.

| Field | Type | Notes |
|-------|------|--------|
| `transactionDate` | `string` | Next **`"yyyy-MM-dd"`** when this row should post (effective date). |
| `kind` | `string` | `standard` \| `transfer` — if `transfer`, set **`fromAccountId`** / **`toAccountId`** (see §4.3). |
| `amountMinor` | `int` | > 0. |
| `direction` | `string` | `in` \| `out`. |
| `currency` | `string` | |
| `accountId` | `string?` | **`kind: standard`** — which account. Omit for **`kind: transfer`** (use from/to). |
| `fromAccountId` | `string?` | **`kind: transfer`** — source account. |
| `toAccountId` | `string?` | **`kind: transfer`** — destination account. |
| `transferGroupId` | `string?` | Optional; links template to future legs. |
| `categoryId` | `string?` | |
| `memo` | `string?` | |
| `recurringRuleId` | `string?` | If spawned from a rule. |
| `cadence` | `string?` | `monthly` \| `twiceMonthly` \| `biweekly` \| `weekly` — same values as `recurring.cadence` (§9); drives **next** date after post in `materializeDueUpcoming`. |
| `daysOfMonth` | `array<int>?` | Days **1–31** for month-based schedules; omit when not used. |
| `weekday` | `int?` | **1–7** (Mon=1 … Sun=7, same as Dart `DateTime.weekday`) when `cadence` is `weekly`. |
| `loadedAt` | `Timestamp` | UTC. |
| `updatedAt` | `Timestamp` | UTC. |

**Materialization (product flow):** When the user opens the app (“first fetch of the day” or on resume), run a **materialization step** (prefer **Callable Cloud Function** for idempotency): query `upcomingTransactions` where **`transactionDate` ≤ today** (user’s calendar today: **IANA `timezone` on profile**, resolved in **`materializeDueUpcoming`**; client may pass `asOfDate` when no TZ). For each doc: if **`kind: standard`**, create **one** `transactions` row; if **`kind: transfer`**, create **two** legs (see §4.3). Then **advance** `transactionDate` on the upcoming doc to the **next period** per `cadence` / `daysOfMonth` / `weekday`, update linked **`recurring`** when `recurringRuleId` is set, or **delete** upcoming + linked rule when no next date is computable. Listeners then refresh dashboard data. See [`data-contract.md`](data-contract.md#11-upcomingtransactions--daily-materialization). Implementation: [`functions/src/scheduleNext.ts`](../functions/src/scheduleNext.ts) + [`functions/src/materialize.ts`](../functions/src/materialize.ts).

---

## 9. `recurring/{ruleId}`

Templates / rules that **create or refresh** `upcomingTransactions` rows (e.g. when a rule is saved). **Locked schema** (aligns with §8 `kind` / accounts / cadence; income vs expense is **`direction` only—no separate `isIncome` flag**):

| Field | Type | Required | Notes |
|-------|------|----------|--------|
| `name` | `string` | ✓ | Display label. |
| `kind` | `string` | ✓ | `standard` \| `transfer` — same meaning as `upcomingTransactions.kind` (§8). |
| `amountMinor` | `int` | ✓ | **> 0**; smallest unit of `currency`. |
| `direction` | `string` | ✓ | `in` \| `out`. |
| `currency` | `string` | ✓ | ISO 4217. |
| `categoryId` | `string?` | | |
| `memo` | `string?` | | |
| `accountId` | `string?` | | **Required** when `kind: standard` — posting account (income deposit or expense withdrawal). |
| `fromAccountId` | `string?` | | **Required** when `kind: transfer`. |
| `toAccountId` | `string?` | | **Required** when `kind: transfer`. |
| `cadence` | `string` | ✓ | `monthly` \| `twiceMonthly` \| `biweekly` \| `weekly` — onboarding maps UI “two paydays” to **`twiceMonthly`** (see [`onboarding.md`](onboarding.md)); **`biweekly`** = fixed **14-day** step from last post. |
| `daysOfMonth` | `array<int>?` | | Days **1–31** for month-based schedules (e.g. `[1, 15]` for twice-monthly); omit when not applicable. |
| `weekday` | `int?` | | **1–7** (Mon … Sun) when `cadence` is **`weekly`** (matches Dart `DateTime.weekday`). |
| `active` | `bool` | ✓ | Default **`true`**. |
| `nextTransactionDate` | `string` | ✓ | Next effective **`"yyyy-MM-dd"`**. |
| `createdAt` | `Timestamp` | ✓ | UTC. |
| `updatedAt` | `Timestamp` | ✓ | UTC. |

**Legacy:** Older docs mentioned `isIncome`; readers may map it to `direction` for one-time migration.

---

## 10. `forexRates/{yyyy-mm-dd}` (global)

**Purpose:** One document per **calendar day** (UTC date key or explicit `date` string—**align with `transactionDate`** keys). Stores rates used to convert **any account/tx currency** → **user main currency** for aggregates.

- **Source:** [Frankfurter API](https://frankfurter.dev/) (e.g. latest rates, historical by date, time series)—**no API key** on public endpoint; **cache** in Firestore to limit outbound calls.
- **Update:** **Scheduled Cloud Function** (daily) fetches and **merges** into `forexRates/{date}`. Reads are **real-time** for clients that listen to aggregates; **rates** themselves update once per day.

**Suggested content:** e.g. map from currency code → multiplier into **MXN** (or store base + quote table—document the exact math in code).

**Missing rate for `transactionDate` (weekend, API lag, holiday gap):** Cloud Functions MUST **not** fail solely because `forexRates/{transactionDate}` is absent. Resolve the rate by using the **previous business day**:

1. Start from `transactionDate` and walk **backward one calendar day at a time** until a document **`forexRates/{yyyy-mm-dd}` exists**.
2. Use the rates from **that** document for conversion (this yields the **latest published** FX prior to the transaction day—typically **Friday** for Sat/Sun once the daily job has stored Friday’s row).
3. Enforce a **max lookback** (e.g. 10–15 days) and **log + alert** if still missing (data pipeline failure); avoid infinite loops.

This is the **only** sanctioned fallback for aggregate conversion in Functions (unless you add explicit holiday calendars later).

---

## 11. Security rules (intent)

- `users/{uid}/**`: `request.auth.uid == uid`.
- **`users/{uid}` profile document:** **Create** must not include **`onboardingCompleted`** or **`integrations`** (there is no **`resource`** on create, so rules must not use **`request.resource.data.diff(resource.data)`** for that path). **Update** rejects any **addition, removal, or in-place change** to **`onboardingCompleted`** and **`integrations`** via **`request.resource.data.diff(resource.data).affectedKeys()`** (use **`affectedKeys`**, not **`changedKeys`**: the latter only lists keys present in **both** before and after with unequal values, so a client could **add** a missing server-only field and bypass a **`changedKeys`** check).
- **`onboardingCompleted`**, **`integrations.*.verifiedAt`**, and any **verified channel identifiers** — prefer **Callable / Admin-only writes** or field-level rules so clients **cannot** forge completion or verification.
- **`forexRates`**: read for authenticated users (or public read if rates are non-sensitive); **write** only from **admin SDK** / scheduled Function.
- **Aggregate docs** (`monthlyTotals`, `accounts.balance*`) — **client direct writes discouraged**; Functions as source of truth for denormalized fields.
- **`_processedAggregateEvents`** — **write** only from Functions (admin SDK); clients must not create these docs.
- **`transactions.*` server-owned fields** — **`aggregateApplied`**, **`aggregateDeferred`**, **`reload`**, **`aggregateReload`**, **`amountMinorMain`**, **`fxRateDateUsed`**: **create/update** only from Cloud Functions (Admin SDK bypasses rules). Clients must not set **`aggregateApplied: true`** (or otherwise forge aggregate state); **`firestore.rules`** rejects writes that add or change these keys.

---

## 12. Resolved decisions (summary)

| Topic | Decision |
|-------|----------|
| Amounts | Positive `amountMinor` + `direction` (`in` / `out`). |
| Transfers | **Two** transactions + `transferGroupId` + `linkedTransactionId`. |
| Dates | `transactionDate` **`yyyy-MM-dd`**; `loadedAt` UTC `Timestamp`; display in user locale. |
| Multi-currency | **Yes**; `mainCurrency` default **MXN**; per-account and per-tx `currency`; aggregates in main currency via **daily** `forexRates` + [Frankfurter](https://frankfurter.dev/). **Missing day:** use **previous calendar day with a stored rate** (walk backward)—implements **previous business day** for typical weekend/holiday gaps. |
| Budgets | **`users/{uid}.budgets`** — same targets every month; UI compares to each month’s aggregates. |
| Upcoming | **`upcomingTransactions`** collection; **materialize** to real `transactions` when due; advance or remove upcoming rows (prefer **Callable** on app open / daily). |
| Transaction delete | **Hard delete**; Functions **reverse** aggregates on delete. |
| Aggregate idempotency | **`_processedAggregateEvents/{eventId}`** + Cloud Function **`event.id`** (§4.1); **catch-up** when meta-only update and not yet applied (§4.1a). |
| Audit on tx | **`amountMinorMain`**, **`fxRateDateUsed`** populated by Functions on write. |
| Net worth vs net cash | **Net worth** = all accounts; **net cash** = accounts with **`includeInNetCash`** (§4.2). |
| Upcoming transfers | **One** upcoming doc per scheduled transfer — **`kind: transfer`**, **`fromAccountId`** / **`toAccountId`**; materializer emits **two** `transactions` (§4.3). |
| Indexes | **`firestore.indexes.json`** — define when queries are fixed (TBD). |
| Onboarding gate | **`onboardingCompleted`** on `users/{uid}`; set **`true`** only after successful server-side commit; gate **not** device-local ([`onboarding.md`](onboarding.md)). |
| Account `type` | Canonical enum **`checking`**, **`savings`**, **`investment`**, **`creditCard`**, **`loan`**, **`mortgage`**; localized labels only in app l10n. |
| Opening balance | Prefer **`transactions`** with **`type: adjustment`** so balances and aggregates stay ledger-driven. |

---

## 13. Revision log

| Date | Change |
|------|--------|
| 2026-04-14 | Initial data model: paths, core fields, `monthlyTotals.days` embedding, real-time-only stance. |
| 2026-04-14 | Resolved: direction + positive amounts, two-leg transfers, `transactionDate`/`loadedAt`, multi-currency + `forexRates` + Frankfurter, budgets in `monthlyTotals`, `upcomingTransactions` + materialization flow. |
| 2026-04-14 | §10: if `forexRates` missing for `transactionDate`, Functions walk backward to **previous stored day** (previous business day behavior); max lookback + logging. |
| 2026-04-14 | §3: `timezone` on user profile (IANA), aligned with materialization “today”. |
| 2026-04-14 | §4.1–4.3: idempotency via `eventId` + `_processedAggregateEvents`; hard delete; audit fields; NW vs net cash; upcoming transfer template; §12 expanded; security for `_processedAggregateEvents`. |
| 2026-04-14 | §4.3: **locked** — scheduled transfers use **one** `upcomingTransactions` template (`kind: transfer`); not two docs per leg. |
| 2026-04-15 | §3: `locale`, `themePreference`, `onboardingCompleted`; §3.1 `integrations` (WhatsApp/Telegram, server-verified); §5: canonical account `type` enum; §6 `iconKey` + onboarding cross-ref; §11 integration/completion write rules; §12 onboarding/account/opening-balance rows. |
| 2026-04-15 | §9: **locked** recurring rule schema (`kind`, `cadence`, `daysOfMonth`, `direction` only — dropped standalone `isIncome`). |
| 2026-04-16 | §4.1a: **`snapshotBalancesIncludedThisRow`** — skip monetary delete/−before when **`aggregateDeferred: true`** or explicit **`aggregateApplied: false`** (any posting date, not only future); fixes **`accounts`** vs `monthlyTotals` drift. |
| 2026-04-16 | Deferred reconcile: **`reconcileDeferredLedgerForUser`** callable + app-driven schedule (replaces scheduled job). |
| 2026-04-16 | §4: **`aggregateDeferred`** for future-dated ledger rows; aggregates skip until posting date ≤ user today + reconcile callable; §4.1a table updated. |
| 2026-04-16 | §4: optional `aggregateApplied`, `reload` / `aggregateReload`; **§4.1a** ledger aggregate trigger (catch-up when meta-only update + not applied), numeric coercion, `days` map clarification. |
| 2026-04-16 | §4 / §11: **`firestore.rules`** block client create/update on **`aggregateApplied`**, **`aggregateDeferred`**, **`reload`**, **`aggregateReload`**, **`amountMinorMain`**, **`fxRateDateUsed`**; reload fields documented as Functions/ops-only. |
| 2026-04-16 | §11: **`users/{uid}`** profile rules (`firestore.rules`): **create** forbids **`onboardingCompleted`** / **`integrations`** (no **`diff`** on create); **update** uses **`diff(...).affectedKeys()`** so adds/removals/changes to those keys are blocked—**`changedKeys()`** would miss first-time **adds** when the prior doc omitted the field. |
| 2026-04-16 | **Budgets** canonical on **`users/{uid}.budgets`** (`{ targetMinorMain, kind }`; legacy flat int on profile); removed from **`monthlyTotals`** (stale month `budgets` ignored); **`commitOnboarding`** + app read profile for targets vs month aggregates. |
| 2026-04-16 | §8–9: `cadence` includes **`weekly`** + optional **`weekday`**; **`daysOfMonth`** / **`weekday`** on `upcomingTransactions`; materializer advances **`recurring.nextTransactionDate`** when **`recurringRuleId`** links; onboarding maps UI biweekly (two DOM) → **`twiceMonthly`**. |
| 2026-04-16 | §5 **accounts**: documented **`iconKey`** and **`colorArgb`** (written by onboarding; client metadata updates via `updateAccountMetadata` must not change balances). |
