# Onboarding

## Route

- **`/onboarding`** — single route; **step index is in-memory state** (Typeform-style wizard). Do not mount the main app shell (bottom nav + drawer) until onboarding completes and the user lands on **`/dashboard`**.

## Entry gate (first login only)

- After **successful auth**, read **`users/{uid}.onboardingCompleted`** ([`data-model.md`](data-model.md) §3).
- Show **`/onboarding`** only when **`onboardingCompleted` is not `true`** (treat missing as **false** for new users).
- **New device / reinstall:** If the user document already has **`onboardingCompleted: true`**, **do not** show onboarding — the gate is **server-backed**, not local-only.
- Set **`onboardingCompleted: true`** only after the **successful, idempotent “commit onboarding”** step (§8) — preferably via **Callable** so the flag cannot be spoofed from a malicious client (see §11 in [`data-model.md`](data-model.md)).

## Purpose

- Collect **profile + preferences**, **accounts**, **categories**, **optional recurring rules per income category**, **budgets**, optional **messaging links**, then **persist** atomically and send the user to the main app.
- Deliver a focused flow: **typed letter-by-letter titles** for step headings, a **persistent progress bar**, and **localized copy** per [`language-and-localization.md`](language-and-localization.md) (ARB / `AppLocalizations`).

## Global UX

- **Typewriter titles:** Each step’s title (and optional subtitle) animates **character by character**. Respect **Reduce motion**: show full title immediately when enabled.
- **Accessibility (semantics):** Expose the **full title as a single accessible label** (e.g. `Semantics` / `header`); **do not** update the accessibility tree on every typed character — screen readers should hear the complete title **once**.
- **Progress bar:** Fixed in a consistent place; **one** bar for the whole flow; advance when steps validate.
- **Navigation:** **Back** preserves valid answers in local state. **Next** disabled until validation passes.
- **Keyboard / small screens:** Scroll safely; primary actions reachable.

## Steps

### 1 — Profile & preferences

- **Display name** — maps to `displayName`; non-empty after trim; max length aligned with [`users/{uid}`](data-model.md).
- **Timezone** — IANA (e.g. `America/Mexico_City`); maps to `timezone`.
- **Theme** — `light` \| `dark` \| `system`; maps to `themePreference`.
- **Language / locale** — BCP 47 (e.g. `es-MX`); maps to `locale`. Follow [`language-and-localization.md`](language-and-localization.md) for supported tags, default (**Spanish**), and persistence. UI strings for onboarding use the **selected locale** once applied (or next app restart if required by implementation).

### 2 — Accounts

- User can **add, edit, remove** accounts. **Gate:** **≥1 account**.
- **Required per account**
  - **Name**
  - **Type** — canonical enum stored as **`checking`**, **`savings`**, **`investment`**, **`creditCard`**, **`loan`**, **`mortgage`** ([`data-model.md`](data-model.md) §5). **UI** shows localized labels from **l10n** keyed by enum value (not free-form strings in Firestore).
  - **Color** — fixed palette / tokens (ARGB or token id).
  - **Currency** — ISO 4217; **default `MXN`**.
- **Optional:** **Starting balance** — minor units; default **0**.
- **Starting balance → persistence (recommended):** Create one **`transactions`** row per non-zero starting balance with **`type: adjustment`** (and appropriate **`direction`** / **`accountId`** / **`currency`**) on the **user’s chosen “as of” business date** (e.g. onboarding day in their **`timezone`**). **Why:** **`balanceMinor`** / aggregates stay driven by the **same** Cloud Functions path as every other movement — no split-brain between “manual balance” and ledger ([`data-model.md`](data-model.md) §4, §5). **Zero** balance needs no row.

### 3 — Categories

- **Example categories** + custom rows; **system category `Fixed Expenses`** (expense) — **selected by default**, cannot be removed.
- **Per category:** name, **`kind`** income/expense, **`iconKey`** from a **Material icon picker** with a **fixed map** (string key → `IconData` / font glyph) — **same keys on web and mobile**; no “native OS icon” free-for-all.
- **Maps to:** `users/{uid}/categories/{categoryId}` ([`data-model.md`](data-model.md) §6).

### 4 — Recurring income (per income category)

- **Only for categories with `kind: income`** (from step 3).
- For **each income category**, ask whether income is **recurring on predictable dates** (e.g. salary on the **1st and 15th**) or **not** (e.g. tips, freelance — variable amount or timing).
- **If recurring:** collect amount (minor units, consistent with **`mainCurrency`**), **deposit `accountId`**, **days of month** (1–31; define end-of-month behavior for invalid days), and **cadence** (e.g. monthly / twice monthly / biweekly) → create **`recurring`** + seeded **`upcomingTransactions`** per backend ([`data-model.md`](data-model.md) §8–9).
- **If not recurring:** **no** recurring rule — user may still set an **expected** amount in **budgets** (next step) without posting fixed schedules.
- **Separation:** **Recurring rules** materialize **real inflows** over time; **budgets** express **expected** monthly totals for projection. They are **not** duplicated on the **projected savings** screen (see step 6).

### 5 — Budgets

- **Per category**, monthly **target** in minor units (**main currency**).
- **Income category** → **expected income** for the month.
- **Expense category** → **expected expenses** for the month.
- **Maps to:** `users/{uid}.budgets` ([`data-model.md`](data-model.md) §3).

### 6 — Projected savings

- **Read-only** summary; user taps **Continue**.
- **Total expected income** = sum of **budgets** on **income** categories (includes salary *expectations* and variable income *ballparks* — whatever they entered in step 5).
- **Total expected expenses — fixed** = budget assigned to the **`Fixed Expenses`** category **only**.
- **Total expected expenses — variable** = sum of **other expense** category budgets (all expense categories **except** `Fixed Expenses`).
- **Projected savings** = expected income − (fixed expenses + variable expenses), all in **main currency**.

### 7 — Messaging (WhatsApp / Telegram)

- Still **in onboarding** for v1; offer **Remind me later** (skips both; no OTP this session).
- Optional: link **WhatsApp** (phone + **OTP**) and/or **Telegram** (**OTP** — standard flow). At most **one** identity per channel per user ([`data-model.md`](data-model.md) §3.1).
- **Backend:** Server-side OTP and persistence of verified identifiers; **not** auth providers ([`settings.md`](settings.md)).
- **Same flows** as Settings later — keep copy and status labels consistent.

### 8 — Commit (loading)

- Full-screen **loading** while **`commitOnboarding`** (Callable) runs: validate payload, **idempotent** by **`requestId`** (UUID) stored under e.g. `users/{uid}/_onboardingCommits/{requestId}` or server-side dedupe table — **safe to retry** on network failure without duplicate accounts/categories/rules.
- Writes: profile fields (**`displayName`**, **`timezone`**, **`themePreference`**, **`locale`**, **`mainCurrency`** from the first onboarding account’s ISO code, **`budgets`** from step 5), accounts, categories, adjustment txs for starting balances, recurring/upcoming, `monthlyTotals/{yyyy-mm}` shell for the current month (aggregates from ledger CF), optional integrations after OTP (or defer integration writes to a follow-up Callable if user already verified in-step).
- Set **`onboardingCompleted: true`** only on successful commit (server-side).

### 9 — Completion

- On success → **`/dashboard`** with shell ([`shell-navigation.md`](shell-navigation.md)).

## Navigation

| From | To |
|------|----|
| Auth success | `/onboarding` if **`onboardingCompleted` ≠ true** |
| Step 8 success | **`/dashboard`** |

## Data (frontend phase)

- **Riverpod** (or equivalent) holds wizard state until commit.
- **Stub** Callables until backend exists; still **model** idempotency keys for tests.

## Security & rules (summary)

- **OTP verification** and **`onboardingCompleted`** — trusted server writes only ([`data-model.md`](data-model.md) §11).
- Clients do not write arbitrary **verified** integration payloads.

## Reuse

- Shared **typewriter header**, **wizard progress**, **Material icon map** → add lines to [`components-inventory.md`](components-inventory.md) when reused.

## Acceptance

- [ ] Gate on **`users/{uid}.onboardingCompleted`**; no onboarding on new device if already completed.
- [ ] Step 1: name, timezone, theme, locale.
- [ ] Account **`type`** stored as canonical enum; labels from **l10n**.
- [ ] Starting balance via **`adjustment`** transactions (or zero — no row).
- [ ] Categories: **Fixed Expenses** + **Material `iconKey` map**.
- [ ] Recurring income: **per income category**; non-recurring → budgets only.
- [ ] Projected: income from **budgets**; fixed = **Fixed Expenses** only; variable = other expense budgets.
- [ ] Messaging: **Remind me later** + **OTP**; server-trusted writes.
- [ ] Commit: **idempotent**; loading then **`/dashboard`**.
- [ ] **Semantics:** full title for screen readers; reduced motion for typewriter.

## Related docs

- [`language-and-localization.md`](language-and-localization.md) — supported locales, ARB, profile `locale`.
- [`data-model.md`](data-model.md) — profile, accounts enum, integrations, transactions.
- [`data-contract.md`](data-contract.md) — streams after onboarding.
- [`settings.md`](settings.md) — messaging parity.
- [`login.md`](login.md) — auth entry.

## Revision log

| Date | Change |
|------|--------|
| 2026-04-16 | **§8 / §5:** Commit payload includes **`profile.mainCurrency`** (first account ISO code); **`budgets`** on **`users/{uid}`**; app invalidates core Firestore stream providers when entering **completion** before **`/dashboard`**. |
