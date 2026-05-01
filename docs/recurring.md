# Recurring

## Route

- `/recurring`

## Purpose

- Show **near-term recurring cash flows**: mini calendar for two weeks, then lists split by horizon.

## UI — title

- Standard screen title.

## UI — “Coming up” paper card

- **Minimalist calendar** covering **current two weeks**:
  - **This week** on **top**
  - **Next week** on **bottom**
- **Very small dot** on any day that has **one or more** recurring transactions.
- **Small green `$` icon** on days with **scheduled income** (subset of dot days).

## UI — “Due soon” section

- **Paper list** of recurring items with next occurrence **within 7 days from now** (inclusive window per product; document chosen rule in code).

## UI — “Coming later” section

- **Paper list** of recurring items with next occurrence **within 15 days from now** but outside “due soon” if overlapping — **clarify**: typically **(7, 15]** days, or “8–15 days”. Implement **8–15 days** unless product overrides (avoid duplicate with due soon).

## Navigation

- **In**: Bottom tab **Recurring**.
- **Out**: Tapping a row may go to detail/edit — **TBD** (not specified); tracked in [`references/product-todos.md`](references/product-todos.md).

## Reuse

- `Two-week mini calendar`, paper list rows (`Transaction row` / recurring variant).

## Data

- **Firestore:** `upcomingTransactions` (canonical next occurrence per scheduled row) plus **`recurring`** for enrichment (rule `name`, linkage via `recurringRuleId`) and **`categories`** for titles/icons — see [`data-contract.md`](data-contract.md) §5 and [`data-model.md`](data-model.md) §8–9.
- **Merged list (KB-008):** The screen watches **`recurringMergedUpcomingProvider`**, which merges **`upcomingTransactions`** (from profile **today** onward), synthetic rows for active **`recurring`** rules not yet represented, and **future-dated `transactions/`** previews (same rules as the dashboard upcoming strip, but **includes due-today** schedule rows).
- **Create rule from ledger (KB-001):** Callable **`createRecurringFromTransaction`** (see `functions/src/createRecurringFromTransaction.ts`) + **Make recurring** in the transaction editor for **standard** rows.
- **“Today”** for list boundaries and the upcoming query lower bound: user profile **`timezone`** (IANA) when set, else device-local calendar date — [`lib/core/datetime/user_calendar_date.dart`](../lib/core/datetime/user_calendar_date.dart), [`todayYyyyMmDdProvider`](../lib/core/data/providers/finko_stream_providers.dart).
- **Due soon / Coming later:** Implemented in [`lib/features/recurring/presentation/recurring_screen.dart`](../lib/features/recurring/presentation/recurring_screen.dart) using `daysBetweenYyyyMmDd(today, transactionDate)` — **Due soon** `0…7`, **Coming later** `8…15` (no overlap).

## Acceptance

- [x] Two-week grid matches “this week / next week” layout.
- [x] Dot vs green `$` distinction for income days.
- [x] Two lists do not duplicate the same item (define date boundaries explicitly in code).

## Revision log

| Date | Change |
|------|--------|
| 2026-04-27 | **Data:** `recurringMergedUpcomingProvider` + future ledger previews; **`createRecurringFromTransaction`** + editor CTA. |
| 2026-04-16 | Firestore-backed screen: profile timezone “today,” `upcomingTransactions` + `recurring` + `categories` streams, refresh/error/retry, row titles/icons; linked deferred row navigation in `docs/references/product-todos.md`. |
