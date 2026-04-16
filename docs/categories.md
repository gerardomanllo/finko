# Categories

## Route

- `/categories`

## Purpose

- Browse all categories, grouped by type.

## UI

- **Full-width paper list**.
- Sections: **Income** categories first, **Expense** categories second (headers or visual separation).
- Each row: icon + name (+ optional metadata later).

## Navigation

- **In**: Drawer → **Categories**.
- **Out**: Row tap → edit/detail — **TBD**.

## Reuse

- Full-width paper list pattern; same row shape as other master lists.

## Data (frontend phase)

- Mock categories with `type: income | expense`.

## Acceptance

- [ ] Income block appears before expense block.
- [ ] Matches list density of other “paper list” screens.
