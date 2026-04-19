# Loans, mortgages, collateral value, and net worth

**Status:** Planning — align on product behavior and data shape before changing [`data-model.md`](data-model.md), aggregates, or UI.

## Why this exists

Today **net worth** is defined as the sum of **account balances** (see [`data-model.md`](data-model.md) §4.2). For **loans** and **mortgages**, the balance is the **liability**: it moves over time with **transactions**, which form the **history of what you owe**.

The ledger does not capture the **value of what secures** that debt (e.g. home, car). This doc defines a **single-account model**: one `loan` or `mortgage` account holds both the **asset (collateral) side** and the **liability (balance) side**, presented like other balance accounts so users see **asset vs liability** and **equity** in one place, and net worth can include that equity when the user opts in.

---

## Resolved decisions

| Topic | Decision |
|-------|----------|
| **Cardinality** | **One collateral value per account** — no separate Property entity for v1. |
| **Account model** | **Asset + liability in one account** — same mental model as checking/savings/investment for “what this account represents”: we store/track **collateral (asset) value**, **current balance (liability)**, and derived **equity**. Not a separate “house” asset duplicated elsewhere. |
| **Currency** | User sets **account currency at creation** (ISO 4217, same as other accounts). **Immutable after creation** — no later edits (avoids mixed-currency drift and ambiguous history). Conversion to **main currency** for aggregates uses the existing [`forexRates`](data-model.md) pipeline where needed. |
| **Net worth** | Including collateral-based **estimates** in headline net worth is **behind a user toggle**. **Default: ON** when the feature ships (user can turn off if they prefer balance-only net worth). Persist on profile (field name TBD in `data-model.md`). |
| **Education / disclaimers** | **In-app copy** should explain how secured accounts work in Finko: collateral is a **user estimate**, liability comes from **transactions**, equity is derived — not bank/legal advice. |
| **Onboarding** | **Required** when we ship: onboarding must collect secured-account fields (currency, initial collateral estimate, liability/opening balance as today) and surface the short education copy. See [`onboarding.md`](onboarding.md) §2. |

---

## Product goals

1. **Collateral value** — User can record and update the **estimated value** of the asset tied to that **single** loan or mortgage account.
2. **Valuation history** — Updates create **historical points** (date + amount + optional note); **transactions** remain the sole history of **liability**.
3. **One screen** — Account detail shows **collateral**, **outstanding balance**, **equity** (asset − liability), with clear labels.
4. **Net worth** — When the toggle is on, net worth includes **equity** from secured accounts (per formula in implementation — avoid double-counting with any future generic “property” assets).

---

## UX principles

- **Optional collateral** — User can skip estimates; equity line hidden or “not set” until they enter a value.
- **Clear labeling** — Separate **estimated asset value** from **loan balance** (statement vs appraisal).
- **Toggle** — Settings (or profile): **Include secured-asset estimates in net worth** — default **on**; when off, net worth uses **account balances only** for those accounts (implementation detail: likely liability balance as today until equity rules are specified in `data-model.md`).

---

## Modeling notes (implementation)

### Single account, two tracked quantities

- **Liability:** `balanceMinor` / `balanceMinorMain` + **transactions** (unchanged ledger semantics).
- **Asset:** latest **collateral** minor amount + **valuation history** subcollection or embedded series (TBD in `data-model.md`).
- **Equity:** derived for display and optional net-worth inclusion — **not** a second account.

### Aggregates / `monthlyTotals`

- Merging **sparse valuations** with **daily liability** for **net worth EOD** remains a Functions/client design task; may **recompute** affected month windows when valuations change.

---

## Related documents

- [`data-model.md`](data-model.md) — Accounts, transactions, net worth.
- [`onboarding.md`](onboarding.md) — Step 2 accounts (secured flow).
- [`settings.md`](settings.md) — Net worth toggle (planned).
- [`backend-strategy.md`](backend-strategy.md) — Aggregation caveats.
- [`ledger-aggregations-and-ui-flow.md`](ledger-aggregations-and-ui-flow.md) — `netWorthEodMinorMain` today.
- [`accounts.md`](accounts.md) — Accounts list.
- [`credit-card-installments.md`](credit-card-installments.md) — Installments on card purchases (separate planning doc).

---

## Open questions (remaining)

1. **Valuation edits** — Append-only history v1 vs allow correcting an old point?
2. **Field names** — Profile flag for the net worth toggle; shape of `accounts` fields for `currentCollateralMinor` vs history-only.

---

## Revision log

| Date | Change |
|------|--------|
| 2026-04-18 | Initial planning doc: collateral value + history vs liability from transactions; equity and net worth accuracy; open questions for implementation. |
| 2026-04-19 | Locked: one value per account; unified asset+liability account; immutable currency; net worth toggle default on; education/disclaimers; onboarding required. Linked installments doc. |
