# Dashboard (Home)

## Route

- `/dashboard` (canonical home route; do not use `/home`).

## Purpose

- Primary overview: net worth, monthly spend snapshot, accounts, upcoming/recent activity, monthly budget teaser.

## UI — top

- **Title** (screen title).
- **Today’s date** — short format matching spec example: **`Tue, Apr 14`** (locale-aware formatting).

## UI — two-card carousel

Horizontal carousel with **exactly two** cards (order as designed):

### Card 1 — Net worth (last 30 days)

- **Top left**: label **“Net Worth”**; below it, net worth value **title-sized**.
- **Top right**: differential vs **latest 30-day period** (sign/format per design system).
- **Body**: line/spark chart for **last 30 days**.
- **Tap entire card** → `/accounts`.

### Card 2 — Total monthly expense (calendar month)

- Same header structure: label (e.g. monthly expense), large amount, period differential (this calendar month vs prior rule — stub if needed).
- **Tap entire card** → `/spending`.

**Reuse**: `Metric carousel card` + chart slot; see **`components-inventory.md`**.

## UI — accounts accordion

- **One row per account type**, ordered for **cash-flow-heavy first**:
  1. Checking
  2. Credit cards
  3. **Net cash** — **aggregate only**, **not clickable**, not an expandable “account”
- Small **spacer**
  4. Savings
  5. Investments

Each row: **icon** (left), **label**, **amount** (right), **chevron/down** to expand.

Expanded: **one row per real account** matching that type. **Net cash**: show aggregate behavior only (no child rows that imply a single account unless product says otherwise).

## UI — upcoming transactions

- **Horizontal row of vertical cards** (carousel or horizontal `ListView`).
- Each card:
  - Small **category** avatar/icon
  - Small label: transaction name
  - **Centered bold**: amount
  - **Footer**: “how many days until” the transaction (copy per design)
- Include only transactions **strictly after today**, **ascending by date** (earliest first).

## UI — recent transactions

- **Paper-style list** of **latest 5** transactions (most recent by posted date).
- Last row: **“See more”** button → `/transactions`.

## UI — monthly budget (single paper card)

- **Row 1**: Icon (left), **“This month’s budget”** (or exact copy), **arrow** (right) suggesting navigation.
- **Row 2** — two columns:
  - **Left column** (three visual rows):
    - Label: **“Left for spending”**
    - Larger **bold** number
    - **Progress bar** under the number
  - **Right column**: **Top 6 categories by spend** for the month — each as **avatar**, white background, **border as progress** toward category budget (or month share — stub logic).
- **Tap anywhere on the card** → `/budgets`.

## Navigation

- **In**: Default tab from shell.
- **Out**: Metric cards → accounts/spending; budget card → budgets; see more → transactions.

## Reuse

- Metric carousel, accounts accordion (cash-flow variant), upcoming card, paper list + see more, monthly budget composite widget.

## Data (frontend phase)

- Mock: net series (30 points), monthly totals, account groups, 5 recent + N upcoming, budget numbers.

## Acceptance

- [ ] Date format matches short weekday + month + day style.
- [ ] Net cash is aggregate and non-clickable.
- [ ] Upcoming sorted ascending; only future dates.
- [ ] Recent capped at 5 with see more.
