# Spending

## Route

- `/spending`

## Purpose

- Analyze spend (and income summary in cards) across selectable **week / month / quarter / year** windows; category breakdown via donut; link target from dashboard card.

## UI — title

- Standard screen title.

## UI — period selection (pill + card)

- **Two-part selection** determines **which slice of data** every section uses (cards, accordion, donut, top transactions):
  1. **Period pill** — granularity: **Week** | **Month** | **Quarter** | **Year** (single selection).
  2. **Period card** — **which** week, month, quarter, or year within the scrollable strip (single selection).
- Example: pill **Month** + card **March 2026** → all widgets reflect March 2026 only.
- Changing the **pill** rebuilds the card strip for that granularity and keeps a sensible default card (see below). Changing the **selected card** updates all dependent sections without changing the pill.

## UI — row of vertical period cards

- Scrollable **row** of **vertical cards** (horizontal scroll).
- **Only periods with activity**: a card appears only if at least one **`transactions`** row has `transactionDate` inside that period (any direction / type). If none, show an empty-state message.
- **Sort**: cards are ordered by **period start date ascending** (oldest on the **left**, most recent on the **right**).
- **Default selection**: the **right-most** card (most recent period **among those shown**) is selected when the screen loads and when the pill changes.
- **Pill change**: the horizontal list **auto-scrolls to the end** (right) so the default / most recent card is in view.
- Each card:
  - **Small “graph-ish”** area with **two columns**: **left = income**, **right = expense** (relative bar heights from **`monthlyTotals.days`** for **week**; merged **`monthlyTotals`** month docs for **month / quarter / year**).
  - **Bottom**: label for that period:
    - **Week mode**: date of **Monday** of that week (or locale start of week).
    - **Month mode**: month name.
    - **Quarter** / **Year**: appropriate label (e.g. `Q1 2026`, `2026`).
- One card per period step in the selected range: **12** periods for week / month / quarter, **8** for year (implementation constants in `lib/core/spending/spending_period_generator.dart`).
- The **selected** card is visually distinct (border, fill, or scale — implementation detail).

## UI — accordion (income + fixed + variable)

- **One card**, **three rows** (same visual language as dashboard-style accordions):
  1. **Income** (week: day-roll sums; month / quarter / year: merged **`monthlyTotals`**).
  2. **Fixed expenses** (gastos fijos).
  3. **Variable expenses**.
- **Non-clickable** (no navigation from rows).
- Each row shows the total for the **currently selected pill + card** period.

## UI — breakdown (paper)

- **Layout**: **Donut on the left**, **category labels on the right**; the **donut + legend row** is **centered horizontally** on the screen (narrow `Row` inside `Center`).
- **Donut**:
  - **Very thin ring** (~1 px stroke: high `centerSpaceRadius` vs section outer radius in fl_chart).
  - **Only the ring borders colored**; **white center**.
- **Center** (inside the ring): label **“Total spend in”** plus the **selected period** (from pill + card, e.g. month name or week context), **bold total** underneath.
- Below chart row: **top 4 transactions by amount** (for the selected period; expense-only unless stated — default **expense**).

## Navigation

- **In**: Bottom tab; dashboard **monthly expense** card may land here with period preset (optional enhancement).
- **Out**: None required for v1.

## Reuse

- Pill group, mini income/expense chart card, **three-row** spending accordion, thin donut + **side legend**, compact transaction rows.

## Data

- **Profile:** `userProfileStreamProvider` → **`mainCurrency`** for formatting; **`todayYyyyMmDdProvider`** for strip bounds (profile timezone when set).
- **Period strip + month / quarter / year totals:** one or more **`monthlyTotals/{yyyy-mm}`** listeners via **`monthlyTotalsForMonthStreamProvider`**; merged in **`spendingMergedMonthlyRollupProvider`** ([`lib/features/spending/presentation/spending_providers.dart`](../lib/features/spending/presentation/spending_providers.dart)). **Week** mini-card income/expense sums **`days.{dd}`** across the week ([`sumDayIncomeExpenseInRange`](../lib/core/spending/spending_rollups.dart)); see [`data-model.md`](data-model.md) §7 (no per-day `byCategory` in Functions).
- **Strip query:** one **`transactions`** stream for the **full candidate window** (first candidate period’s start → last candidate period’s end); the UI filters periods client-side to those with ≥1 transaction, then filters rows again for the **selected** period.
- **Week donut + fixed/variable + top 4:** same ledger slice as above; aggregate outflows (non-`transferLeg`) using **`amountMinorMain`** when set, else **`amountMinor`** only if **`currency`** equals the user’s **`mainCurrency`** (so top transactions still populate before CF stamps `amountMinorMain`).
- **Month / quarter / year donut + fixed/variable:** signed **`byCategoryMinorMain`** on merged month docs; UI maps **expense** categories to **positive** spend for the ring; **fixed** = category id **`fixed-expenses`** (onboarding system category); **variable** = total expense minus fixed ([`lib/core/spending/fixed_variable_expense.dart`](../lib/core/spending/fixed_variable_expense.dart)).
- **Categories:** **`categoriesStreamProvider`** for labels, colors, and expense-kind filter on category maps.

## Acceptance

- Pill + card together drive all sections consistently; default card is the most recent.
- Period cards are ordered oldest → newest, left → right.
- Accordion shows **income**, **fixed expenses**, and **variable expenses** in one card; non-interactive.
- Donut is a thin ring with category labels in a **right-hand** legend; center label includes selected period wording.

## Revision log

- **2026-04-16**: **One accordion** (income + fixed + variable); **auto-scroll strip** to the right on pill change; donut + legend **centered horizontally**.
- **2026-04-16**: Strip shows **only periods with ≥1 transaction**; donut ring **thinner**; top outflows use **`amountMinorMain`** with **`amountMinor`** fallback when currency matches **`mainCurrency`**.
- **2026-04-16**: **Implemented** Flutter wiring: `monthlyTotals` merge + optional **`transactions`** range stream; **`fixed-expenses`** split; **`FinkoDonutWithSideLegend`** + **`FinkoSpendingIncomeFixedVariableAccordion`**; strip counts (12 / 8).
- **2026-04-16**: Specified **pill + card** as the data selector; cards **ascending by date** with **right-most default**; accordion **fixed vs variable** expense rows; **thin donut** with **legend to the right** of the chart.
