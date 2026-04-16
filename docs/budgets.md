# Budgets

## Route

- `/budgets`

## Purpose

- Month-centric budget overview: spending pace, bills vs earnings, savings target progress, per-category budgets.

## UI — title

- Standard screen title.

## UI — month navigation (not a date picker)

- **Input-like row**:
  - **Left**: calendar icon.
  - **Center**: label **“This month”** when viewing current month; when paginating, show **that month’s** name (e.g. **March 2026**) — still no day selection.
  - **Right**: **Previous** / **Next** chevrons to move **by whole months** only.
- **No** date-picker popover for picking arbitrary days.

## UI — full-width “Spending” card

- **Top row**: icon (left); **top right**: **`$xx/day for X days`** (pace to end of month — stub formula).
- **Middle**: label **“Spending”** with **`$XXX.XX left to spend`** (large emphasis).
- **Bottom**: **progress bar** with **left** label **`$X,XXX.XX spent`** and **right** label **`$xx,xxx budgeted`**.

## UI — two small cards (same row)

- **Left card**: **“Bills & Utilities”** — content per design (amounts/progress stub).
- **Right card**: **“Earnings”** — same.

Use a **responsive row**: side-by-side on wide width; stacked on narrow if needed.

## UI — large “Savings” card

- **Two columns**:
  - **Left**: icon top-left; label **“Projected savings”** above a **bold** **`$X,XXX`**; sublabel **“Of $X,XXX target”** (match formatting).
  - **Right**: **simple one-column vertical bar/column chart** — wide column; **Y-axis** from **`$0`** to **short target** (e.g. target `$2,900` → axis max **`$2.9k`** style).

## UI — category budgets

- **Paper list** of **all categories**, grouped: **Income** section first, **Expense** section second.
- Each row:
  - **Left**: category **icon** with **border as progress** (ring toward budget consumption).
  - **Middle**: category name + subtitle **`$x,xxx left to spend`** (or income equivalent — expense-focused copy per spec).
  - **Right**: **total spent** (or earned for income categories).

## Navigation

- **In**: Dashboard **monthly budget** card.
- **Out**: Row tap → category budget detail — **TBD**.

## Reuse

- Month paginator field, progress bars, savings chart card, category ring row (same avatar/border pattern as dashboard).

## Data (frontend phase)

- Mock month index, spending totals, category lines, savings target.

## Acceptance

- [ ] Month changes only via prev/next, not day picker.
- [ ] Spending card shows pace, left to spend, spent vs budgeted.
- [ ] Savings chart Y-axis uses abbreviated large targets as specified.
