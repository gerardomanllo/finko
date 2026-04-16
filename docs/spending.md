# Spending

## Route

- `/spending`

## Purpose

- Analyze spend (and income summary in cards) across selectable **week / month / quarter / year** windows; category breakdown via donut; link target from dashboard card.

## UI — title

- Standard screen title.

## UI — period pills

- **Four pills**, **single selection**: **Week** | **Month** | **Quarter** | **Year**.
- Changing pill refreshes all dependent sections (cards, accordion totals, donut label, top transactions).

## UI — row of vertical period cards

- Scrollable **row** of **vertical cards** (horizontal scroll).
- Each card:
  - **Small “graph-ish”** area with **two columns**: **left = income**, **right = expense** (relative heights or mini bars — stub).
  - **Bottom**: label for that period:
    - **Week mode**: date of **Monday** of that week (or locale start of week).
    - **Month mode**: month name.
    - **Quarter** / **Year**: appropriate label (e.g. `Q1 2026`, `2026`).
- One card per period step in the selected range (how many weeks/months back — product default, e.g. last 6 or 12; stub).

## UI — accordion (income / expense only)

- Same **visual language** as dashboard accounts accordion but:
  - Only **Income** and **Expense** sections.
  - **Non-clickable** (no navigation from rows).

## UI — breakdown (paper)

- **Full width**:
  - **Donut / pie**: **only the ring borders colored**; **white center**.
  - Center text: label **“Total spend in”** plus the **selected period** (e.g. week/month/quarter/year context), **bold total** underneath.
- Below chart: **top 4 transactions by amount** (for the selected period; expense-only unless stated — default **expense**).

## Navigation

- **In**: Bottom tab; dashboard **monthly expense** card may land here with period preset (optional enhancement).
- **Out**: None required for v1.

## Reuse

- Pill group, mini income/expense chart card, accordion variant (2 sections), donut chart + centered labels, compact transaction rows.

## Data (frontend phase)

- Mock series per period; mock transactions for top 4.

## Acceptance

- [ ] Pills drive all sections consistently.
- [ ] Accordion matches non-interactive requirement.
- [ ] Donut matches ring-only aesthetic; center label includes selected period wording.
