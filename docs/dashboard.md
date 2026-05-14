# Dashboard (Home)

## Route

- `/dashboard` (canonical home route; do not use `/home`).

## Purpose

- Primary overview: net worth, monthly spend snapshot, accounts, upcoming/recent activity, monthly budget teaser.

## UI — top

- **App bar title**: **today’s date** only — short format matching spec example: `**Tue, Apr 14`** (locale-aware `DateFormat`), **centered** in the bar (settings remains leading; trailing uses a width placeholder so the title centers on screen).
- **Body** opens with the **two-card metric carousel** (no duplicate date line under the app bar).

## UI — two-card carousel

Horizontal carousel with **exactly two** cards (order as designed):

- **Screen layout**: Carousel uses the **same 20pt horizontal gutter** as **“Cuentas”** and the blocks below; **`viewportFraction` below 1.0** shows a **thin sliver** of the sibling card inside that content width (not edge-to-edge on the phone).
- **Gutter**: small horizontal inset on each page so the two cards **do not touch** when side by side.
- **Pagination**: **two centered dots** under the carousel track the active card.

### Card 1 — Net worth (last 30 days)

- **Top left**: label **“Net Worth”**; below it, net worth value **title-sized**.
- **Top right**: differential vs **latest 30-day period** (sign/format per design system) — **stub copy** in app strings until real period-over-period math ships.
- **Body**: line/spark chart for **last 30 calendar days** from **`monthlyTotals` → `days.{dd}.netWorthEodMinorMain`**, each point the **signed sum of all accounts** in main currency (written by Cloud Functions; may span **one to three** month docs; missing days forward-filled). If the series is all zeros, the **large amount** falls back to the **sum of all account balances** (main currency).
- **Footer** (bottom of card): full-width row — **“Ver mis cuentas”** (localized) **on the left**, **chevron on the right**; chart sits in a **flexible** slot above a fixed bottom strip so the footer aligns to the **card bottom** without a blank gap under the sparkline (chart grows into the middle space). Same tap target: entire card → `/accounts`.
- **Tap entire card** → `/accounts`.

### Card 2 — Total monthly expense (calendar month)

- Same header structure: label (e.g. monthly expense), large amount, top-right **period differential** (still **stub copy** — not yet computed vs prior month).
- **Amount** (large number): **MTD expense** through profile **today** — **`expenseMinorMainThroughDate`** on **`monthlyTotals/{dashboardYearMonth}`** (same month key as the net worth card’s calendar context).
- **Body**: **line/area chart** — **one point per calendar day** in that month (28–31 points on the X axis); each Y value is **cumulative spend from day 1 through that day** (sum of **`monthlyTotals.days.{01..dd}.expenseMinorMain`**; missing days count as `0` so the curve **holds flat** until more spend appears). Same chart widget shell as net worth (`FinkoNetWorthSparkline`).
- **Footer** (bottom of card): same row pattern as net worth — **“Ver mis gastos”** (localized) **on the left**, **chevron on the right**; fixed bottom strip + flexible chart slot above.
- **Tap entire card** → `/spending` (via `go_router`).

**Reuse**: `Metric carousel card` + chart slot; see `**components-inventory.md`**.

## UI — accounts accordion

- **One row per account type**, ordered for **cash-flow-heavy first**:
  1. Checking
  2. Credit cards
  3. **Net cash** — **aggregate only**, **not clickable**, not an expandable “account”; trailing **info** icon opens a short explanation of how net cash is calculated (localized).
- Small **spacer**
  1. Savings
  2. Investments

Each row: **icon** (left), **label**, **amount** (right), **chevron/down** to expand.

Expanded: **one row per real account** matching that type. **Net cash**: show aggregate behavior only (no child rows that imply a single account unless product says otherwise).

## UI — upcoming transactions

- **Entire section omitted** when there are **no** upcoming rows (no heading, no empty placeholder).
- **No** outer paper / tinted surface: the row sits on the **same scaffold background** as the heading; only each **item card** has its own surface.
- **Horizontal row of vertical cards** (horizontal `ListView`): up to **five** upcoming rows from the merged strip, then a **“See all upcoming”** card → **`/recurring`** (Recurring tab: calendar + due-soon / coming-later lists).
- Each transaction card (content **horizontally centered** in the card):
  - **Category icon avatar** (`FinkoCategoryIconAvatar`): Material icon from `iconKey` on a neutral circle; tint from stored **`colorArgb`** or a deterministic theme fallback by `categoryId` when unset.
  - Small label: transaction name
  - **Centered bold**: amount
  - **Footer**: “how many days until” the transaction (copy per design)
- Include only transactions **strictly after today**, **ascending by date** (earliest first).

## UI — recent transactions

- **Paper-style list** of **latest 5** transactions (most recent by posted date). Each row leading: **category icon avatar** (same tint rules as upcoming).
- Last row: **“See more”** button → `/transactions`.

## UI — monthly budget (single paper card)

- **Row 1**: Icon (left), **“This month’s budget”** (or exact copy), **arrow** (right) suggesting navigation.
- **Row 2** — two columns:
  - **Left column** (three visual rows):
    - Label: **“Left for spending”**
    - Larger **bold** number
    - **Progress bar** under the number
  - **Right column**: **Top 6 expense categories** by MTD spend in **`byCategoryMinorMain`** (only rows whose **`categories/{id}`** is **`kind: expense`**; income categories omitted). Shown in a **2 rows × 3 columns** grid. Each cell: **`FinkoCategoryIconAvatar`** inside an **outer progress ring** (same rules as before: vs **`budgets.{categoryId}.targetMinorMain`** when that target is positive, else vs **max spender** among those six). Ring color from **`colorArgb`** or deterministic fallback by `categoryId`.
- **Tap anywhere on the card** → `/budgets`.

## Navigation

- **In**: Default tab from shell.
- **Out**: Metric cards → accounts/spending; budget card → budgets; see more → transactions; **dashboard upcoming “see all”** → **Recurring** (`/recurring`).

## Reuse

- Metric carousel, accounts accordion (cash-flow variant), upcoming card, paper list + see more, monthly budget composite widget.

## Data & implementation status

Implementation: `lib/features/dashboard/presentation/dashboard_screen.dart` + providers in `lib/core/data/providers/finko_stream_providers.dart`.

| Area | Source | Notes |
|------|--------|--------|
| **Net worth value + sparkline** | `netWorthSparklineSeriesProvider` | Last 30 calendar days ending on profile **today** (`todayYyyyMmDdProvider`), from `monthlyTotals.days` (+ forward-fill). |
| **Monthly expense card + running-total chart** | `monthlyTotalsForMonthStreamProvider(dashboardYearMonthProvider)` + **`dashboardMonthDailyExpenseSeriesProvider`** | Large amount: **MTD** via `expenseMinorMainThroughDate` (same day-sum as budget teaser); chart: **cumulative** spend through each calendar day (full month length 28–31). |
| **Main currency** | `userProfileStreamProvider` (`mainCurrency`) | Fallback: first account currency or `MXN`. |
| **Accounts + net cash** | `accountsStreamProvider` | Net cash = sum of `balanceMinorMain` / `balanceMinor` for accounts with **`includeInNetCash`** (Firestore field; client infers checking/creditCard when omitted — see `data-model.md` §5 / §4.2). |
| **Budget teaser** | Same month doc as above | **Left for spending** = sum of expense **`budgets.{id}.targetMinorMain`** − **MTD** expense (same day-sum as the card). Category rings scale `byCategoryMinorMain` by MTD/full-month expense when day-level categories are not stored; ring **fill** uses **`positiveExpenseMinorFromSignedNet`** on that scaled map (signed net → positive expense), matching budget rollups. |
| **Upcoming strip** | `dashboardUpcomingStripProvider` | **`mergeUpcomingForUi`** (`includeDueToday: false`): `upcomingTransactions` **after** today + **`futureDatedLedgerTransactionsStreamProvider`** (ledger rows dated after today) + active **recurring** previews when not already listed; sorted ascending. Transfer **in** legs omitted (out leg only). **Dashboard UI:** section hidden when empty; **≤5** preview + **see all** → **`/recurring`**. |
| **Recent list** | `recentTransactionsStreamProvider` | Last **5** with `transactionDate` **on or before** profile **today** (excludes future-dated ledger rows). |
| **Pull-to-refresh** | `RefreshIndicator` | Calls **`ledgerAwareAppRefreshProvider.runPullToRefresh`** (shared with Recurring / Transactions): throttle, server profile gate, **`materializeDueUpcoming`**, conditional **`reconcileDeferredLedgerForUser`**, canonical provider invalidation — see **`data-contract.md` §11**. |

**Still stub / placeholder:** metric card **delta** strings (both cards).

## Acceptance

- Date format matches short weekday + month + day style.
- Net cash is aggregate and non-clickable; info icon explains the calculation.
- Upcoming: **hidden** when none; otherwise sorted ascending, future dates only, **max five** preview cards + **see all** → Recurring.
- Recent capped at 5 with see more.
- Monthly expense chart: **one point per calendar day** in `dashboardYearMonth` (28–31 points); each value is **running total** spend from day 1 through that day (`dashboardMonthDailyExpenseSeriesProvider`).

## Revision log

| Date | Change |
|------|--------|
| 2026-05-13 | **Monthly budget card — category rings:** arc progress uses **positive expense** from signed `byCategoryMinorMain` (`positiveExpenseMinorFromSignedNet`); ring **track** matches `/budgets` compact bar (`FinkoColors.grayLight`). |
| 2026-05-13 | **Monthly budget card (dashboard):** category grid shows **expense categories only** (income omitted from top-6 selection). |
| 2026-05-13 | **Monthly budget card:** top-6 category cells are a **2×3** grid; each shows **category icon** (`FinkoCategoryIconAvatar`) inside the existing **progress ring** (`FinkoCategoryAvatarRing` + `FinkoBudgetTeaserCategoryRing` data). |
| 2026-05-13 | **Category visuals:** Recent + upcoming use **`FinkoCategoryIconAvatar`**; **`categoriesStreamProvider`** for tints; **category editor** `colorArgb` + **`commitOnboarding`**. (Budget teaser icon+ring grid: see adjacent row.) |
| 2026-05-13 | **Upcoming** (dashboard): **hide whole section** when the merged list is empty; show **at most five** items + trailing **see all** card → **`/recurring`**; strings **`dashboardUpcomingSeeAll`** (`FinkoUpcomingSeeAllCard`). |
| 2026-05-13 | **Upcoming** strip: removed outer **`FinkoPaperCard`** wrapper so the horizontal row has **no extra section background** (individual upcoming cards unchanged). |
| 2026-05-13 | **Upcoming** strip cards: avatar, title, amounts, and days-until footer **horizontally centered** (`FinkoUpcomingTransactionCard`). |
| 2026-05-13 | **Monthly expense card**: bottom **footer** (“See my spending” / “Ver mis gastos”) + chevron, same pattern as net worth card; tap still opens **Spending**. |
| 2026-05-13 | **Monthly expense card**: full-month line chart via `dashboardMonthDailyExpenseSeriesProvider` — **running total** spend (cumulative `expenseMinorMain` by day); earlier same-day **per-day** chart superseded. |
| 2026-05-13 | Metric carousel defaults: **`viewportFraction` 0.98**, **`cardHorizontalInset` 4** — wider cards, thinner sibling peek. |
| 2026-05-13 | Metric carousel: `PageView` + dashboard `ListView` use **`clipBehavior: Clip.none`** so rounded cards are not clipped at viewport edges. |
| 2026-05-13 | Two-metric **carousel**: same **20pt body gutter** as lists below; **viewportFraction** + per-page inset for sibling **peek**; **dots**; net worth **footer** bottom-aligned; removed body **headline**. |
| 2026-05-13 | App bar: **date** as centered title (removed separate “Panel” / screen title and duplicate date in body). |
| 2026-05-12 | Net worth card: chart points are **signed sum of all accounts** (`netWorthEodMinorMain` from Functions + optional month replay); sparkline may load **up to three** intersecting **`monthlyTotals`** month docs. |
| 2026-04-27 | **Upcoming strip** row: documents **`mergeUpcomingForUi`** (`includeDueToday: false`). |
| 2026-04-18 | **Pull-to-refresh** documents shared **`ledgerAwareAppRefreshProvider`** pipeline (dashboard + other tabs); see **`data-contract.md` §11**. |
| 2026-04-16 | Próximos include **future-dated `transactions/`** rows (editor), not only `upcomingTransactions` + recurring. |
| 2026-04-16 | Recent transactions exclude future-dated rows; próximos merge **upcoming** + **recurring**; dashboard month key follows profile today; expense/budget rings use **MTD through today**; net-worth window ends on profile today. |
| 2026-04-16 | Net cash row: **info** icon + dialog with localized explanation of how net cash is summed (`includeInNetCash`, defaults, `balanceMinorMain` / `balanceMinor`). |
| 2026-04-16 | Replaced “frontend mock” section with **live Firestore-backed** dashboard mapping (streams, fallbacks, stubs). Documented net worth series, monthly totals, accounts/net cash, budget teaser, refresh + materialization, and remaining UI stubs (**deltas** only). |

