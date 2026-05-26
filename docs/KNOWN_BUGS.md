# Known bugs (living doc)

Triaged items from the **Finko (Responses)** Google Form → Sheet (**tab `responses`**), excluding rows whose **Status** is **`Done`** or **`Not a bug`**.

| Source | Spreadsheet `responses` tab; sync with MCP per [`references/google-sheets-bug-mcp.md`](references/google-sheets-bug-mcp.md) |
|--------|-------------------------------------------------------------------------------------------------------------------------------|

## How to use this doc

1. **Sheet is canonical for reporter input** (timestamps, screenshots, raw Spanish copy). This file adds **engineering context**: where we think the bug lives, whether we **agreed on a fix**, and if it is **ready to implement**.
2. When the sheet **Status** changes to `Done` or `Not a bug`, **remove** that bug’s section here (or move to a “Resolved” appendix if you want history—today we keep only open items).
3. When new rows appear in the sheet with other statuses (`To-do`, `Backlog`, etc.), **add** a new `KB-xxx` block using the template below.
4. **`Discussed fix`** — Has the team (or you + agent) talked through expected behavior and approach? (`No` / `In progress` / `Yes`)
5. **`Ready to fix`** — Is there enough clarity to open a PR without more product/design input? (`No` until scope and acceptance are clear.)

## Team answers (sync)

Captured **2026-04-27** when tightening priority 4–5 items:

| Question | Answer |
|----------|--------|
| **KB-001** MVP | **Create a new recurring rule from this transaction** (cadence UX aligned with onboarding income: monthly / twice-monthly / weekly + days). |
| **KB-008** surface | Reporter / expectation aligns with **Recurring** screen lists — **not** the Dashboard strip (those already merge extra sources). |
| **KB-002** repro | **Month** pill on Spending (not Week). |
| **KB-003** evidence | **Two real `transactions` rows** in Firestore on the duplicate day — not UI-only phantom. |

## Shipped in repo (update sheet when you mirror)

| ID | What shipped |
|----|----------------|
| **KB-001** | Callable **`createRecurringFromTransaction`** + **Make recurring** on standard transaction editor ([`ledger_transaction_editor_sheet.dart`](../lib/widgets/transactions/ledger_transaction_editor_sheet.dart)); seeds `recurring` + `upcomingTransactions`. |
| **KB-002** | Month/quarter/year **fixed/variable accordion** uses **`splitFixedVariableFromPositiveSlices`** so totals align with **donut** slices ([`fixed_variable_expense.dart`](../lib/core/spending/fixed_variable_expense.dart), [`spending_screen.dart`](../lib/features/spending/presentation/spending_screen.dart)). |
| **KB-003** | **`materializeDueUpcoming`** uses **deterministic** `transactions` doc ids per upcoming + date (and transfer leg pair ids) to prevent duplicate posts on retry/concurrency ([`materialize.ts`](../functions/src/materialize.ts)). |
| **KB-008** | **`recurringMergedUpcomingProvider`** + **`mergeUpcomingForUi`** — Recurring screen matches dashboard merge (**today-inclusive** for schedule rows + ledger futures) ([`finko_stream_providers.dart`](../lib/core/data/providers/finko_stream_providers.dart)). |
| **KB-004** | **`isFixedExpense`** on expense categories; fixed/variable rollups and Budgets **Fixed expenses** card sum flagged categories (replaces system **`fixed-expenses`** bucket). |

## Index (open items)

Search this file for **`KB-00N`** to jump to a bug.

| ID | Sheet row | Status (sheet) | Priority | Area (sheet) | Title |
|----|-----------|------------------|----------|--------------|--------|
| KB-005 | 9 | Backlog | 4 | TODOS | Floating menu |
| KB-006 | 12 | Backlog | 4 | Transacciones | `$` beside amount |
| KB-007 | 13 | Backlog | 4 | Home | Net worth vs accounts |
| KB-009 | 15 | Backlog | 3 | home / global | Transaction list icons |
| KB-010 | 20 | Backlog | 3 | Home | Credit card strip + income card |
| KB-011 | 21 | Backlog | 3 | Transacciones | “Nota” vs descripción copy |
| KB-012 | 23 | Backlog | 2 | TODO | iOS-style scrolls / pickers |
| KB-013 | 24 | Backlog | 1 | Home | Profile entry placement |

---

### KB-005 — Global / floating menu

| Field | Value |
|-------|--------|
| **Sheet row** | 9 |
| **Submitted** | 2026-04-21 |
| **Status (sheet)** | Backlog |
| **Tipo** | Feature |
| **Reporter summary** | Menu should be floating and round (FAB-style). |
| **Discussed fix** | No |
| **Ready to fix** | No — needs design reference (shell: bottom nav + drawer per [`shell-navigation.md`](shell-navigation.md)). |
| **Likely code / product area** | Shell scaffold / `NavigationBar` / FAB placement — TBD. |

**Open questions:** FAB replaces **center** tab, or secondary FAB above nav? **Web** same as mobile?

---

### KB-006 — Transacciones / currency `$` beside amount

| Field | Value |
|-------|--------|
| **Sheet row** | 12 |
| **Submitted** | 2026-04-21 |
| **Status (sheet)** | Backlog |
| **Tipo** | Correccion |
| **Reporter summary** | Show `$` (or currency symbol) next to amount field for clarity. |
| **Discussed fix** | No |
| **Ready to fix** | **Partial** — small UI change once rule is chosen: always **`mainCurrency`** symbol vs **account currency** symbol vs **ISO code** from `intl`/existing formatters. |
| **Likely code / product area** | [`lib/widgets/transactions/ledger_transaction_editor_sheet.dart`](../lib/widgets/transactions/ledger_transaction_editor_sheet.dart) amount field; reuse [`lib/core/formatting/money_format.dart`](../lib/core/formatting/money_format.dart) / `formatMinorUnitsWithCode`. |

**Open questions:** Reporter asked for **`$`** — for **MXN** do we show **`MXN`**, **`$`**, or **`$` + “MX”`** per locale?

---

### KB-007 — Home / net worth vs accounts

| Field | Value |
|-------|--------|
| **Sheet row** | 13 |
| **Submitted** | 2026-04-21 |
| **Status (sheet)** | Backlog |
| **Tipo** | Bug |
| **Reporter summary** | Net worth total does not match expectation from accounts list. |
| **Discussed fix** | No |
| **Ready to fix** | No — decide after confirming whether the **net worth card amount** is “wrong” or **accounts list interpretation** differs from product definition. |
| **Likely code / product area** | [`lib/features/dashboard/presentation/dashboard_screen.dart`](../lib/features/dashboard/presentation/dashboard_screen.dart) (~lines 139–144); `netWorthFromAccountsMinor` vs sparkline; [`docs/data-model.md`](data-model.md) §4.2 signed net worth. |

**Acceptance (from sheet):** Explanation in UI (tutorial or info icon).

**Engineering notes**

- The **net worth metric card value** uses **`netWorthSparklineSeriesProvider`’s last point** when any sparkline point is non-zero; **otherwise** it uses **`netWorthFromAccountsMinor(accounts)`**. If sparkline series is **stale or differently defined** than live account balances, the big number can disagree with the **accounts accordion** below (still sum of accounts).
- **Hypothesis:** Mismatch is often **sparkline path vs accounts path**, not raw arithmetic on the accordion.
- **Open questions:** If sparkline is disabled or empty, does the card amount match sum of accounts? Should the card **always** equal `netWorthFromAccounts` and move history to a secondary widget?

---

### KB-009 — Transactions / category icons

| Field | Value |
|-------|--------|
| **Sheet row** | 15 |
| **Submitted** | 2026-04-21 |
| **Status (sheet)** | Backlog |
| **Tipo** | Feature |
| **Reporter summary** | Use category icons more clearly on transaction rows (wherever lists appear). |
| **Discussed fix** | No |
| **Ready to fix** | No — list screens to touch. |

---

### KB-010 — Home / credit card strip + income card

| Field | Value |
|-------|--------|
| **Sheet row** | 20 |
| **Submitted** | 2026-04-21 |
| **Status (sheet)** | Backlog |
| **Tipo** | Correccion |
| **Reporter summary** | Credit cards shown as accumulated spend; wants chart similar to patrimonio; suggests an income card. |
| **Discussed fix** | No |
| **Ready to fix** | No — dashboard layout / metrics definition. |

---

### KB-011 — Transacciones / “Nota” vs descripción copy

| Field | Value |
|-------|--------|
| **Sheet row** | 21 |
| **Submitted** | 2026-04-21 |
| **Status (sheet)** | Backlog |
| **Tipo** | Correccion |
| **Reporter summary** | Rename “nota” to context-specific strings (gasto vs ingreso). |
| **Discussed fix** | No |
| **Ready to fix** | No — l10n + field labels only once copy is approved. |
| **Likely code / product area** | Transaction editor ARBs — TBD. |

---

### KB-012 — TODO / iOS-style scrolls

| Field | Value |
|-------|--------|
| **Sheet row** | 23 |
| **Submitted** | 2026-04-21 |
| **Status (sheet)** | Backlog |
| **Tipo** | Feature |
| **Reporter summary** | iOS-like wheel scrolls for calendar and pickers (“app fina”). |
| **Discussed fix** | No |
| **Ready to fix** | No — large UX scope; may defer. |

---

### KB-013 — Home / profile entry placement

| Field | Value |
|-------|--------|
| **Sheet row** | 24 |
| **Submitted** | 2026-04-21 |
| **Status (sheet)** | Backlog |
| **Tipo** | Correccion |
| **Reporter summary** | Remove prominent text; move account access to top-right (profile icon only?). |
| **Discussed fix** | No |
| **Ready to fix** | No — home header layout. |

---

## Template for new bugs (copy below the index)

```markdown
### KB-0NN — Short title

| Field | Value |
|-------|--------|
| **Sheet row** | (1-based row in `responses` tab) |
| **Submitted** | YYYY-MM-DD |
| **Status (sheet)** | To-do / Backlog / … |
| **Tipo** | Bug / Feature / Correccion |
| **Reporter summary** | One paragraph from the form + link to Screenshots column in sheet if needed. |
| **Discussed fix** | No / In progress / Yes — (date, who, notes) |
| **Ready to fix** | No / Yes — link PR or branch when started |
| **Likely code / product area** | e.g. `lib/features/transactions/...` |

**Acceptance (from sheet):** …
```

## Revision log

| Date | Change |
|------|--------|
| 2026-04-27 | **Shipped KB-001, 002, 003, 008:** moved to **Shipped in repo** table; removed full sections for those IDs. Recurring merge provider; spending fixed/variable from positive slices; materialize deterministic tx ids; `createRecurringFromTransaction` + editor CTA. |
| 2026-04-27 | **Tighten P4–P5:** Team answers block (KB-001 create-rule MVP, KB-008 Recurring screen, KB-002 Month, KB-003 two real txs). Expanded **KB-001–KB-008** with code pointers, hypotheses, open questions; KB-007 net worth sparkline vs accounts path; KB-008 ready-to-fix **Yes (engineering)** with provider merge explanation. |
| 2026-04-27 | Initial doc: 13 open items from **Finko (Responses)** `responses` tab (rows with Status ≠ Done / Not a bug). Added discussion + ready-to-fix fields. |
