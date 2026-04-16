# Transactions

## Route

- `/transactions`

## Purpose

- Full ledger: search/filter and chronological list (newest first).

## UI — title

- Standard screen title.

## UI — search / filter bar

- Full-width **search** (debounced) and **filter** button: opens a **bottom sheet** to choose **All** or a [`LedgerTransactionKind`](data-model.md) (standard, transfer leg, adjustment); search matches memo and document id client-side. If there are no matches in loaded pages but more history exists, the app **loads older pages in the background** with a status line + spinner (see [`data-contract.md`](data-contract.md) §9).

## UI — transaction list

- **Full-width paper list**.
- **All transactions** sorted **descending by date** (newest at top).
- Each row: match app list pattern (icon, title, amount, date line as per theme).

## Navigation

- **In**: Bottom tab **Transactions**; **See more** from dashboard.
- **Out**: Row tap → **ledger editor** slide-up (edit mode); same pattern on Dashboard recent list and Spending top transactions.

## Reuse

- Search/filter bar widget, paper list, shared transaction row, [`LedgerTransactionEditorSheet`](../lib/widgets/transactions/ledger_transaction_editor_sheet.dart) for create (center +) and edit (row tap).

## Data

- **List:** Firestore **cursor pagination** (20 rows per page, `transactionDate` descending), infinite scroll near list bottom; **not** a live snapshot of the full collection (see [`data-contract.md`](data-contract.md) §9). Dashboard “recent” still uses the small real-time stream.
- **Search:** Client-side match on loaded rows; background sequential page fetches when needed.

## Acceptance

- [x] Descending by date verified (query + UI).
- [x] Search bar + type filter; debounced search; optional full-history scan UX when no local match.

## Revision log

| Date | Change |
|------|--------|
| 2026-04-16 | Ledger editor: **no type field** — income/expense saves as **standard** (editing **adjustment** preserves type). **Transfer** is a third option next to income/expense: **from/to account**, two **`transferLeg`** rows in one batch. |
| 2026-04-16 | Ledger editor: **category is required** (income/expense must match direction); inline validation highlights missing fields. |
| 2026-04-16 | Implemented paginated ledger list, filter ring, debounced search + background history scan, pull-to-refresh; shell **New** opens **ledger editor** slide-up (no `/transactions/new` route). |
| 2026-04-16 | Filter control: **bottom sheet** with explicit type options (replaces tap-to-cycle). |
| 2026-04-16 | **Create/edit** via shared [`LedgerTransactionEditorSheet`](../lib/widgets/transactions/ledger_transaction_editor_sheet.dart) slide-up (row tap = edit). |
