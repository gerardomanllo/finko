# Dashboard (Home)

## Route

- `/dashboard` (canonical home route; do not use `/home`).

## Purpose

- Primary overview: net worth, monthly spend snapshot, accounts, upcoming/recent activity, monthly budget teaser.

## UI — top

- **Title** (screen title).
- **Today’s date** — short format matching spec example: `**Tue, Apr 14`** (locale-aware formatting).

## UI — two-card carousel

Horizontal carousel with **exactly two** cards (order as designed):

### Card 1 — Net worth (last 30 days)

- **Top left**: label **“Net Worth”**; below it, net worth value **title-sized**.
- **Top right**: differential vs **latest 30-day period** (sign/format per design system) — **stub copy** in app strings until real period-over-period math ships.
- **Body**: line/spark chart for **last 30 calendar days** from **`monthlyTotals` → `days.{dd}.netWorthEodMinorMain`** (may span two month docs; missing days forward-filled). If the series is all zeros, the **large amount** falls back to the **sum of all account balances** (main currency).
- **Tap entire card** → `/accounts`.

### Card 2 — Total monthly expense (calendar month)

- Same header structure: label (e.g. monthly expense), large amount, top-right **period differential** (still **stub copy** — not yet computed vs prior month).
- **Amount** comes from **`monthlyTotals/{yyyy-mm}.expenseMinorMain`** (device-local calendar month via `currentYearMonthProvider`).
- **Body**: placeholder **bar chart icon** (not a live series yet).
- **Tap entire card** → `/spending` (via `go_router`).

**Reuse**: `Metric carousel card` + chart slot; see `**components-inventory.md`**.

## UI — accounts accordion

- **One row per account type**, ordered for **cash-flow-heavy first**:
  1. Checking
  2. Credit cards
  3. **Net cash** — **aggregate only**, **not clickable**, not an expandable “account”
- Small **spacer**
  1. Savings
  2. Investments

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
  - **Right column**: **Top 6 categories by spend** for the month (`byCategoryMinorMain`, sorted by amount) — each as **avatar**, white background, **border as progress** toward that category’s budget when **`budgets.{categoryId}.targetMinorMain` > 0**; otherwise progress vs the **max spender** in the top-6 list (fallback). Ring labels may show **truncated category ids** until category names are resolved in-widget.
- **Tap anywhere on the card** → `/budgets`.

## Navigation

- **In**: Default tab from shell.
- **Out**: Metric cards → accounts/spending; budget card → budgets; see more → transactions.

## Reuse

- Metric carousel, accounts accordion (cash-flow variant), upcoming card, paper list + see more, monthly budget composite widget.

## Data & implementation status

Implementation: `lib/features/dashboard/presentation/dashboard_screen.dart` + providers in `lib/core/data/providers/finko_stream_providers.dart`.

| Area | Source | Notes |
|------|--------|--------|
| **Net worth value + sparkline** | `netWorthSparklineSeriesProvider` | Last 30 days from `users/{uid}/monthlyTotals/{yyyy-mm}.days` (+ forward-fill). |
| **Main currency** | `userProfileStreamProvider` (`mainCurrency`) | Fallback: first account currency or `MXN`. |
| **Monthly expense card** | `currentMonthTotalsStreamProvider` | `MonthlyTotals.expenseMinorMain` for current `yyyy-MM`. |
| **Accounts + net cash** | `accountsStreamProvider` | Net cash = sum of `balanceMinorMain` / `balanceMinor` for accounts with **`includeInNetCash`** (Firestore field; client infers checking/creditCard when omitted — see `data-model.md` §5 / §4.2). |
| **Budget teaser** | Same month doc as above | **Left for spending** = sum of expense **`budgets.{id}.targetMinorMain`** − `expenseMinorMain` (clamped). Parser accepts **`{ targetMinorMain, kind }`** rows or **legacy** flat `categoryId → minor` (coerced as expense targets). |
| **Upcoming strip** | `upcomingTransactionsStreamProvider` | Filtered to dates **strictly after** `todayYyyyMmDdProvider`; sorted ascending. |
| **Recent list** | `recentTransactionsStreamProvider` | Last **5** shown. |
| **Pull-to-refresh** | `RefreshIndicator` | Invalidates dashboard-related providers and runs **`materializeDueUpcoming`** (see `data-contract.md` §11). |

**Still stub / placeholder:** metric card **delta** strings (both cards), monthly expense **chart** (icon only).

## Acceptance

- Date format matches short weekday + month + day style.
- Net cash is aggregate and non-clickable.
- Upcoming sorted ascending; only future dates.
- Recent capped at 5 with see more.

## Revision log

| Date | Change |
|------|--------|
| 2026-04-16 | Replaced “frontend mock” section with **live Firestore-backed** dashboard mapping (streams, fallbacks, stubs). Documented net worth series, monthly totals, accounts/net cash, budget teaser, refresh + materialization, and remaining UI stubs (deltas, expense chart). |

