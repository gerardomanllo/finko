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
- **Out**: Tapping a row may go to detail/edit — **TBD** (not specified).

## Reuse

- `Two-week mini calendar`, paper list rows (`Transaction row` / recurring variant).

## Data (frontend phase)

- Mock recurring rules with `nextDate`, `isIncome`, `name`, `amount`, `categoryIcon`.

## Acceptance

- [ ] Two-week grid matches “this week / next week” layout.
- [ ] Dot vs green `$` distinction for income days.
- [ ] Two lists do not duplicate the same item (define date boundaries explicitly in code).
