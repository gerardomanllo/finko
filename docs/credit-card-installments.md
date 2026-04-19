# Credit card installments (meses sin intereses / deferred payments)

**Status:** Planning — define behavior and ledger shape before changing [`data-model.md`](data-model.md), the transaction editor, and aggregates.

## Why this exists

Many users **split a card purchase** into **fixed monthly charges** (installments / *meses sin intereses* / *pagos diferidos*). Today a card charge is typically **one** `transactions` row. We need a **first-class way** to represent **N payments** tied to **one purchase**, so:

- The **statement balance** and **cash planning** reflect **what posts each month**, not only the full purchase amount on day one.
- **History** and **recurring materialization** can align with how banks book installments.

This doc is **independent** from secured loan/mortgage collateral ([`loans-collateral-and-net-worth.md`](loans-collateral-and-net-worth.md)) but may share patterns (e.g. **parent/child** transaction links, **`upcomingTransactions`**).

---

## Product goals (draft)

1. **Optional at entry** — When adding or editing a **credit card** expense, user can mark it as **installment** and set **number of payments** (and optionally **first payment date** or **aligned billing cycle** rules — TBD).
2. **Ledger truth** — Either **one parent transaction** + **scheduled/upcoming child postings**, or **N posted rows** with a shared **`installmentGroupId`** — implementation choice (see below). **Sum of posted parts** must match **total purchase** (minor units, same currency as account).
3. **UX** — List and detail show **installment progress** (e.g. “3/12”) and link to the **purchase** line.
4. **Categories / spending** — Decide whether **full amount** hits the expense category **up front** (budget impact once) vs **per payment** (spread) — product decision with budget/spending docs.

---

## Modeling options (for engineering discussion)

| Approach | Pros | Cons |
|----------|------|------|
| **A — One `transactions` row + `upcomingTransactions` template** | Matches existing recurring/upcoming patterns; clear “purchase” row | Functions materialize N charges; need **`kind: "installment"`** and fields on upcoming row |
| **B — N `transactions` rows, batch-created** | Simple balance math per month | Many rows; editing/cancel mid-stream is harder |
| **C — Parent metadata + children** | Clear hierarchy | More complex queries; rules for delete/edit |

**Account constraint:** Installments apply to **`creditCard`** accounts only (v1).

---

## Open questions

1. **Interest / fees** — v1 **zero-interest** installments only, or allow fee fields?
2. **Early payoff** — User pays remaining principal in one tx: how to **close** the plan?
3. **Spending charts** — Full amount in purchase month vs amortized by payment month ([`spending.md`](spending.md), [`budgets.md`](budgets.md)).
4. **Cross-month `monthlyTotals`** — Each posted installment leg should follow the same **aggregate** rules as a normal card **out** (see [`ledger-aggregations-and-ui-flow.md`](ledger-aggregations-and-ui-flow.md)).

---

## Related documents

- [`data-model.md`](data-model.md) — `transactions`, `upcomingTransactions`, `creditCard` accounts.
- [`transactions.md`](transactions.md) — Ledger UI.
- [`recurring.md`](recurring.md) — Scheduled items (partial overlap with installment schedules).

---

## Revision log

| Date | Change |
|------|--------|
| 2026-04-19 | Initial planning doc: installment purchases on credit cards; goals; modeling options; open questions. |
