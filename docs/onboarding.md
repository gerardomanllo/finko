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
- **Theme** — `light` \| `dark` \| `system`; maps to `themePreference`. **UI** labels the system option **“Automatic”** (EN) / **“Automático”** (ES); wire value stays **`system`**.
- **Language / locale** — BCP 47 (e.g. `es-MX`); maps to `locale`. Follow [`language-and-localization.md`](language-and-localization.md) for supported tags, default (**Spanish**), and persistence. UI strings for onboarding use the **selected locale** once applied (or next app restart if required by implementation).
- **Main currency** — ISO 4217 (e.g. `MXN`); maps to **`users/{uid}.mainCurrency`** on commit. Chosen here explicitly (not inferred from account order).

### 2 — Accounts

- User can **add, edit, remove** accounts. A **system Cash** row (`type: cash`, id `cash`) is **always present**: localized name **Cash** / **Efectivo**, **currency** and **starting balance** user-editable, **not deletable**. **Gate:** **≥1 account** is always satisfied by Cash; users typically add bank-style accounts on top.
- **Required per account**
  - **Name**
  - **Type** — canonical enum stored as **`cash`**, **`checking`**, **`savings`**, **`investment`**, **`creditCard`**, **`loan`**, **`mortgage`** ([`data-model.md`](data-model.md) §5). **UI** shows localized labels from **l10n** keyed by enum value (not free-form strings in Firestore). Users **cannot** add a second **`cash`** account from onboarding (only the system row).
  - **Color** — curated **named palette** (~24 colors) with **localized names** (EN/ES, e.g. *Sky blue* / *Azul cielo*); account editor uses a **dropdown** of named swatches (no hex shown). Stored as **ARGB `int`** in `colorArgb`.
  - **Currency** — ISO 4217; **default `MXN`**. For **`loan`** and **`mortgage`** (when [secured-account collateral](loans-collateral-and-net-worth.md) ships): **required**, **immutable after onboarding commit** — user cannot change currency later.
  - **Credit cards:** optional **total credit line** (`creditLimitMinor` in account currency) collected in the account editor.
- **Secured accounts (`loan`, `mortgage`)** — When collateral ships: collect **initial collateral / asset estimate** (optional or required per product), **starting liability balance** (existing **starting balance** path), and short **education** on how Finko shows **asset vs liability** in **one account** (see [`loans-collateral-and-net-worth.md`](loans-collateral-and-net-worth.md)). Same step 2; no separate Property entity.
- **Optional:** **Starting balance** — minor units; default **0**.
- **Starting balance → persistence (recommended):** Create one **`transactions`** row per non-zero starting balance with **`type: adjustment`** (and appropriate **`direction`** / **`accountId`** / **`currency`**) on the **user’s chosen “as of” business date** (e.g. onboarding day in their **`timezone`**). **Why:** **`balanceMinor`** / aggregates stay driven by the **same** Cloud Functions path as every other movement — no split-brain between “manual balance” and ledger ([`data-model.md`](data-model.md) §4, §5). **Zero** balance needs no row.

### 3 — Categories

- **Example categories** + custom rows; **system category `Fixed Expenses`** (expense) — **selected by default**, cannot be removed.
- **Per category:** name, **`kind`** income/expense, **`iconKey`** from a **fixed map** (string key → `IconData` / font glyph) chosen via **dropdown** — **same keys on web and mobile**; no “native OS icon” free-for-all.
- **Maps to:** `users/{uid}/categories/{categoryId}` ([`data-model.md`](data-model.md) §6).

### 4 — Recurring income (per income category)

- **Only for categories with `kind: income`** (from step 3).
- For **each income category**, ask whether income is **recurring on predictable dates** (e.g. salary on the **1st and 15th**) or **not** (e.g. tips, freelance — variable amount or timing).
- **If recurring:** collect amount (minor units, consistent with **`mainCurrency`**), **deposit `accountId`**, **days of month** (1–31; define end-of-month behavior for invalid days), and **cadence** (e.g. monthly / twice monthly / biweekly) → create **`recurring`** + seeded **`upcomingTransactions`** per backend ([`data-model.md`](data-model.md) §8–9). The corresponding **income** category **budget** is kept in sync with that recurring row as a **monthly** expectation: **monthly ×1**, **biweekly ×2**, **weekly ×4** on `amountMinor` — **on every recurring update** (amount or cadence), not only the first time they open **Budgets** (step 5). If they turn **recurring off**, the budget is **not** auto-cleared (they may have edited it on the budgets step).
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
- **Chart:** one **stacked column**; **expense** bands (fixed + every variable category) are **ordered by budget amount** (**largest next to $0**, then smaller, then **projected savings** at the top / 100% expected income; green/red/zero for savings). **Y-axis** from **0** to **expected income** (no intermediate grid steps). **Labels** to the right of each band: **`Category` `pct`% − `amount`**. If **projected savings &lt; 0**, the top segment is **red** with **NO SAVINGS − {amount} OVER INCOME** (localized), and expense bands below **scale** to fit the column height.

### 7 — Messaging (WhatsApp / Telegram)

- Still **in onboarding** for v1; offer **Remind me later** — clears optional channel state and **advances** like **Next** (no OTP this session).
- Optional: link **WhatsApp** (phone + **OTP**) and/or **Telegram** (**magic link** to the bot — same flow as Settings; see [`references/telegram-bot-webhook.md`](references/telegram-bot-webhook.md)). At most **one** identity per channel per user ([`data-model.md`](data-model.md) §3.1).
- **Backend:** Server-side OTP (**WhatsApp**) or signed-in magic link (**Telegram**); **not** auth providers ([`settings.md`](settings.md)).
- **Same flows** as Settings later — keep copy and status labels consistent.

### 8 — Commit (loading)

- Full-screen **loading** while **`commitOnboarding`** (Callable) runs: validate payload, **idempotent** by **`requestId`** (UUID) stored under e.g. `users/{uid}/_onboardingCommits/{requestId}` or server-side dedupe table — **safe to retry** on network failure without duplicate accounts/categories/rules.
- Writes: profile fields (**`displayName`**, **`timezone`**, **`themePreference`**, **`locale`**, **`mainCurrency`** from **step 1** (explicit picker), **`budgets`** from step 5), accounts (including **`cash`**, **`creditLimitMinor`**, **`isSystem`** as written), categories, adjustment txs for starting balances, recurring/upcoming, `monthlyTotals/{yyyy-mm}` shell for the current month (aggregates from ledger CF), optional integrations after OTP (or defer integration writes to a follow-up Callable if user already verified in-step).
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
- [ ] Messaging: **Remind me later** + **WhatsApp OTP** / **Telegram link**; server-trusted writes.
- [ ] Commit: **idempotent**; loading then **`/dashboard`**.
- [ ] **Semantics:** full title for screen readers; reduced motion for typewriter.

## Related docs

- [`language-and-localization.md`](language-and-localization.md) — supported locales, ARB, profile `locale`.
- [`data-model.md`](data-model.md) — profile, accounts enum, integrations, transactions.
- [`data-contract.md`](data-contract.md) — streams after onboarding.
- [`settings.md`](settings.md) — messaging parity.
- [`login.md`](login.md) — auth entry.
- [`loans-collateral-and-net-worth.md`](loans-collateral-and-net-worth.md) — secured loan/mortgage onboarding + collateral (planned).

## Revision log

| Date | Change |
|------|--------|
| 2026-05-22 | Category/budget lists use **`onboardingCategoriesForDisplay`**: income → **Fixed Expenses** → other expenses (stable within each group). |
| 2026-05-22 | **§4** Account/weekday chips use **`OnboardingChoiceChip`** (cloud fill, visible borders). **§5** Budget targets in per-category **cards** with income/expense badges. **§6** Projected step scrollable; chart **fixed 280px** in card. **Review:** all categories listed with kind cues; recurring copy in **natural language**. |
| 2026-05-22 | **§1** Theme, locale, and main currency use **segmented toggles** (not dropdowns). **§2–3** “Add” buttons sit **above** account/category lists. **§4** Recurring income cards use icon header, yes/no toggle, and chip pickers. **§6 / review** Projected savings hero + metric tiles; review step uses section cards. |
| 2026-04-22 | **§2** Account **color** dropdown shows **named colors** (EN/ES, curated ~24-color palette) instead of hex; account + category **icon** dropdowns show **localized labels** (EN/ES) instead of raw icon keys. Stored `colorArgb` / `iconKey` values unchanged. |
| 2026-04-22 | **§6** Stacked column: all **expense** rows (fixed + each variable) **sorted by budget amount** (largest next to $0, smallest expense just under savings); **projected savings** at the top (100% expected income). |
| 2026-04-22 | **§4** Income **budget** stays aligned with **recurring** (cadence multipliers) whenever recurring is edited, not only on first visit to budgets. |
| 2026-04-22 | **§2** Account/category icon + account **color** dropdowns: `ConstrainedBox` + `Row` + `Expanded` text, **`selectedItemBuilder`** for the collapsed value (avoids [ListTile] / unbounded `Text` in the field’s ~24px-tall selected row). |
| 2026-04-21 | **§1** Main currency + theme **Automatic** (`system` wire). **§2** System **`cash`** (starting balance + currency), credit line, color/icon dropdowns. **§4–5** Recurring→income budget prefill (cadence multipliers); **single** state update when entering **budgets** so fields match seed. **§6** Stacked projected chart (**full step height**; blue fixed/variable; savings always **top**, green/red/zero). **§7** Remind me later advances. **§8** `mainCurrency` from step 1. |
| 2026-04-21 | **§7 Messaging:** Telegram **magic-link only** (no OTP); WhatsApp still OTP; deep link / webhook reference unchanged. |
| 2026-04-19 | **§2 Accounts:** Note **immutable currency** and **secured-account** (loan/mortgage) fields + education when collateral ships; link to planning doc. |
| 2026-04-16 | **§8 / §5:** Commit payload includes **`profile.mainCurrency`**; **`budgets`** on **`users/{uid}`**; app invalidates core Firestore stream providers when entering **completion** before **`/dashboard`**. *(Source of `mainCurrency` superseded 2026-04-21: explicit step 1 picker.)* |
