# Categories

## Route

- `/categories`

## Purpose

- Browse all categories, grouped by type.

## UI

- **Full-width paper list**.
- Sections: **Income** categories first, **Expense** categories second (section headers).
- Each row: **icon** (from `iconKey`) + **name** + trailing **signed month total** (device calendar month from `monthlyTotals`, main currency).

## Navigation

- **In**: Drawer → **Categories**.
- **Out**: Row tap → **bottom sheet**: month total, recent transactions for the month, **Edit category** (same bottom-sheet pattern as onboarding; fixed-expenses category locks income/expense kind). **Delete category** (destructive cascade) is in the editor sheet for non-system categories; after a successful cascade delete, the editor and summary sheets close and the list is shown again.

## Add

- **Floating extended FAB** (bottom center, tonal): **Add category** → onboarding-style editor → `FirestoreDataRepository.createCategory`. List / empty state use extra bottom padding so rows are not covered by the FAB.

## Reuse

- Full-width paper list pattern; same row shape as other master lists.

## Data (frontend phase)

- Mock categories with `type: income | expense`.

## Acceptance

- [x] Income block appears before expense block.
- [x] Matches list density of other “paper list” screens.
- [x] Add category and cascade delete (with confirmation) for user categories; fixed-expenses and internal transfer category are not deletable from UI.

## Revision log

- **2026-04-18**: Add category CTA as **center-floating extended FAB** (was inline list button); delete from editor with cascade (`deleteCategoryCascade`); reserved **`ledger-transfer`** category omitted from list stream.
- **2026-04-16**: Summary transaction lines use the same **main / native** amount rules as the transactions list (`amountMinorMain` or same-currency `amountMinor` fallback).
- **2026-04-16**: List driven by `categories` collection (with icons); row opens summary sheet + onboarding-style editor; `FirestoreDataRepository.updateCategory`.
