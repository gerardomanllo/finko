# Accounts

## Route

- `/accounts`

## Purpose

- View all accounts grouped by **account type** (read-only list for v1 unless specified).

## UI

- **Full-width paper list** showing **all accounts**.
- Grouped **per account type** (section headers aligned with dashboard cash-flow order: checking, credit cards, savings, investments, loans, mortgage).
- Each row: **icon** (from `iconKey`, optional `colorArgb` avatar) + **name** + localized type subtitle + balance right-aligned per theme.

## Navigation

- **In**: Drawer → **Accounts**; dashboard **Net Worth** metric card.
- **Out**: Row tap → **bottom sheet**: month net (main currency) from ledger rows in range, recent transactions, **Edit** (onboarding account sheet **without** starting-balance field); `FirestoreDataRepository.updateAccountMetadata` (name, type, currency, icon, color, `includeInNetCash` — not balances).

## Reuse

- Same grouped list pattern as categories; align icons with dashboard accordion.

## Data (frontend phase)

- Mock accounts with `type` and `balance`.

## Acceptance

- [x] Grouping matches dashboard account taxonomy where applicable.
- [x] Accessible from Net Worth card navigation.

## Revision log

- **2026-04-16**: Month net in account summary sums **main-currency comparable** ledger amounts (`amountMinorMain`, or `amountMinor` when row currency equals profile main); foreign rows without a main stamp are omitted from that sum and show **native** signed amounts per line (matches transactions list semantics).
- **2026-04-16**: Icons on rows; summary sheet + metadata-only editor; repository `updateAccountMetadata`; `FinkoAccount` reads `iconKey` / `colorArgb` from Firestore.
