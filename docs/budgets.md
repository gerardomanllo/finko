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

- **Top row**: icon (left); **top right**: `**$xx/day for X days`** (pace to end of month — stub formula).
- **Middle**: label **“Spending”** with `**$XXX.XX left to spend`** (large emphasis).
- **Bottom**: **progress bar** with **left** label `**$X,XXX.XX spent`** and **right** label `**$xx,xxx budgeted`**.

## UI — two small cards (same row)

- **Layout (compact tile, not the large spending block):** light **surface** card, soft elevation; **top:** line icon (receipt-style for bills, savings-style for earnings); **section title**; **main line** = formatted **amount** (bold, compact type) with a **smaller caption directly beneath** (**Left to pay** / **To earn**); **thin pill progress**; **footer** (**{amount} paid** / **{amount} earned**) unchanged. No pace line on these tiles.
- **Left card**: **“Bills & Utilities”**. **Data:** budget = `users/{uid}.budgets['fixed-expenses'].targetMinorMain` (system **fixed-expenses** category — [`spending.md`](spending.md)); spent = positive outflow from signed `monthlyTotals.byCategoryMinorMain['fixed-expenses']` for the viewed month ([`data-model.md`](data-model.md) §3 + §7). Main amount = **budget − spent** (clamped ≥ 0); bar = spent ÷ budget when budget > 0; footer = spent.
- **Right card**: **“Earnings”**. Let **X** = sum of `users/{uid}.budgets.{categoryId}.targetMinorMain` over every Firestore **income** category (`categories[].kind == income`); **Y** = **`incomeMinorMain`** on the viewed **`monthlyTotals/{yyyy-mm}`** (month inflows, all categories). Main amount = **X − Y** (clamped ≥ 0); bar = **Y ÷ X** when **X > 0** (clamped 0…1); footer = **Y** (earned).

Use a **responsive row**: side-by-side on wide width; stacked on narrow if needed.

**Widget:** [`FinkoBudgetCompactSummaryCard`](../lib/widgets/budgets/finko_budget_compact_summary_card.dart).

## UI — large “Savings” card

- **Two columns**:
  - **Left**: icon top-left; label **“Projected savings”** above a **bold** `**$X,XXX`**; sublabel **“Of $X,XXX target”** (match formatting).
  - **Right**: **simple one-column vertical bar/column chart** — wide column; **Y-axis** from `**$0`** to **short target** (e.g. target `$2,900` → axis max `**$2.9k`** style).

## UI — category budgets

- **Section title** (l10n): **Spending by category** / **Gastos por categoría** — **expense budgets only** (no income section in this list).
- **Paper list** of **expense** `users/{uid}.budgets.*` rows (`kind == expense`), **and** any row whose Firestore category has **`kind: income`** is omitted (guards legacy / mismatched budget maps). Rows are **sorted by category budget** (`targetMinorMain`) **descending**, then by `categoryId` for a stable order.
- Each row:
  - **Left**: category **icon** with **border as progress** (ring toward budget consumption). When the budget target is **positive** and **actual spend** (positive expense from signed `byCategoryMinorMain`) **exceeds** that target, a **small warning icon** appears at the **top-right** of the avatar (localized tooltip).
  - **Middle**: **Firestore category `name`** (fallback: `categoryId`) + subtitle: **`{amount} available`** / **`{amount} disponible`** when spend ≤ budget (`{amount}` = remainder, clamped ≥ 0); **`{amount} over`** / **`{amount} de más`** when spend exceeds budget (`{amount}` = overspend).
  - **Right**: **positive** actual spend for the month (signed `byCategoryMinorMain` is negative for outflows).

## Navigation

- **In**: Dashboard **monthly budget** card.
- **Out**: Row tap → category budget detail — **TBD**.

## Reuse

- Month paginator field, progress bars, savings chart card, category ring row (same avatar/border pattern as dashboard).

## Data

- **Subscriptions:** **`userProfileStreamProvider`** for **`users/{uid}.budgets`**; **`monthlyTotalsForMonthStreamProvider(yyyy-mm)`** for the pager month’s spend/income; **`categoriesStreamProvider`** for `categories/{id}.name`, `kind`, and icon/color when those are wired into the row later.
- Shared rollup helpers: [`lib/core/budget/monthly_budget_rollup.dart`](../lib/core/budget/monthly_budget_rollup.dart) (`totalExpenseBudgetMinor`, `totalIncomeBudgetMinor`, **`incomeCategoryBudgetTargetMinor`**, `fixedExpensesBudgetAndSpent`, signed-net → positive minors) — first argument is the profile **`budgets`** map where applicable.

## Acceptance

- Month changes only via prev/next, not day picker.
- Spending card shows pace, left to spend, spent vs budgeted.
- Savings chart Y-axis uses abbreviated large targets as specified.

## Revision log

| Date | Change |
|------|--------|
| 2026-05-13 | Category row subtitle: **remaining** vs **over** copy (l10n; ES: “{amount} disponible” / “{amount} de más”). |
| 2026-05-13 | Category list: sort by **budget target** descending; **over-budget** rows show a **warning** on the avatar (tooltip). |
| 2026-04-16 | Bottom list sorted by **category spend** (minor, descending). |
| 2026-04-16 | Bottom list: skip budget rows tied to Firestore **income** categories even if `budgets.*.kind` were wrong. |
| 2026-04-16 | **Earnings** tile: **X** = sum of budget targets on **income** Firestore categories; **Y** = `incomeMinorMain`; compact tile shows amount + caption under amount; list title **Gastos por categoría** and **expense** budget rows only. |
| 2026-04-16 | Small budget tiles use **`FinkoBudgetCompactSummaryCard`** (mock-aligned: icon, single headline, pill bar, paid/earned footer) instead of the large **Gasto** progress block. |
| 2026-04-16 | Wired **Bills & Utilities** and **Earnings** cards to `monthlyTotals` (fixed-expenses vs income budgets + `incomeMinorMain`); category rows use Firestore **name**, **Available / To earn** subtitles with remainder amounts, positive expense actuals; added `monthly_budget_rollup.dart`. |
| 2026-04-16 | **Canonical budgets** on **`users/{uid}.budgets`**; month doc only for actuals; docs + UI wired to profile stream. |
