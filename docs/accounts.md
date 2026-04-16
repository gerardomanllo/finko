# Accounts

## Route

- `/accounts`

## Purpose

- View all accounts grouped by **account type** (read-only list for v1 unless specified).

## UI

- **Full-width paper list** showing **all accounts**.
- Grouped **per account type** (section headers: Checking, Savings, Credit, Investment, etc. — align with dashboard types).
- Each row: institution/name, mask/last4 optional, balance right-aligned per theme.

## Navigation

- **In**: Drawer → **Accounts**; dashboard **Net Worth** metric card.
- **Out**: Row tap → account detail — **TBD**.

## Reuse

- Same grouped list pattern as categories; align icons with dashboard accordion.

## Data (frontend phase)

- Mock accounts with `type` and `balance`.

## Acceptance

- [ ] Grouping matches dashboard account taxonomy where applicable.
- [ ] Accessible from Net Worth card navigation.
