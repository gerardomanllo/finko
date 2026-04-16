# Transactions

## Route

- `/transactions`

## Purpose

- Full ledger: search/filter and chronological list (newest first).

## UI — title

- Standard screen title.

## UI — search / filter bar

- Full-width **search** and/or **filter** controls (categories, accounts, date range — stub filters acceptable; bar must exist).

## UI — transaction list

- **Full-width paper list**.
- **All transactions** sorted **descending by date** (newest at top).
- Each row: match app list pattern (icon, title, amount, date line as per theme).

## Navigation

- **In**: Bottom tab **Transactions**; **See more** from dashboard.
- **Out**: Row tap → detail — **TBD**.

## Reuse

- Search/filter bar widget, paper list, shared transaction row.

## Data (frontend phase)

- Mock list with sortable dates.

## Acceptance

- [ ] Descending by date verified.
- [ ] Search bar present (can filter client-side mock).
