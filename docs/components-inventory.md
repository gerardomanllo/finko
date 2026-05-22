# Shared components & DRY map

Use these names as **implementation targets** (rename to match `lib/` conventions). When two screens need the same structure, **extract** rather than fork.

## Layout & shell

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **App shell** | `Scaffold` + bottom navigation + center plus action + `Drawer` toggled from top-left settings cog; **`AgentEntryPill`** overlay on tab routes only | All main tabs |
| **Agent screen** | Full-screen chat (`/agent`): **`AgentStatusRow`**, **`AgentFailedRow`**, **`AgentMessageBubble`**, **`AgentActionChips`**, **`AgentComposer`** | [`agent.md`](agent.md) |
| **App drawer** | Rich shell drawer: profile (avatar + display name) + plan stub chip; **paper-style** net worth block (dashboard metric vocabulary) + stub month delta; MTD income / expense / savings on **cloud**/**navy** fills; nav rows match bottom-nav tints (**Dashboard** shell branch, **Categories**, **Accounts**, **Settings**) | [`finko_shell_drawer.dart`](../lib/features/shell/presentation/finko_shell_drawer.dart) |
| **Screen scaffold** | Title (and optional actions) consistent with app style | Most routes |

## Surfaces

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Messaging connected sheet** | WhatsApp/Telegram identity + verified date + disconnect | Settings (`settings_messaging_sheets.dart`); Telegram adds **Bot defaults** → `telegram_bot_preferences_sheet.dart` |
| **Paper card / paper section** | Full-width or inset “paper” surface (elevation, padding); `InkWell` only when `onTap` is set (scrollable lists use plain padding). Without `title`, child is not wrapped in a min-height `Column` so **`ListView`** + **`RefreshIndicator`** get bounded height | Dashboard, recurring, spending, transactions, budgets, categories, accounts |
| **Ledger-aware pull refresh** | `ledgerAwareAppRefreshProvider.runPullToRefresh` — throttle, server timestamp gate, materialize + conditional reconcile, canonical `ref.invalidate` | Dashboard, Recurring, Transactions (`RefreshIndicator`); **required** for new refresh surfaces per `shell-navigation.md` |
| **Pill toggle group** | Single-select pills (segmented control style) | Spending (`week` / `month` / `quarter` / `year`) |

## Formatting

| Helper | Responsibility | Used on |
|--------|------------------|---------|
| **`ledger_transaction_amount`** | `signedMinorMainComparableOrNull` (main stamp or same-currency fallback), `transactionAmountPrimarySecondary` (compact row primary/secondary like transactions list) | Category/account month summary sheets |

## Metrics & charts

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Metric carousel card** | Top-left label, large value, top-right period delta; optional **`expandChartVertically`** + **footer** (bottom-aligned in a fixed bottom strip); tappable | Dashboard (Net Worth, Monthly expense) |
| **Two-card horizontal carousel** | `PageView` inside dashboard **body gutter**; **viewport fraction** + per-page horizontal inset (gap between cards, peek of sibling); **centered dot** indicators under the chart block | Dashboard |
| **Net worth sparkline / line chart** | Time series in metric cards: **~30d net worth** or **full-month cumulative expense** | Dashboard |
| **Mini income vs expense chart** | Two columns (income \| expense) “graph-ish” per period; optional **selected** border + tap | Spending (row of vertical period cards) |
| **Donut / ring pie chart** | Colored **ring only**; white center with title + bold total | Legacy / reuse |
| **Donut + side legend** | Thin ring + **legend on the right** (swatch, name, amount, %); **centered horizontally**; center: title + period subtitle + bold total. On **Spending**, strip / accordion / donut / **top transactions** are separate surfaces with **cloud** gutters; **top transactions** uses a **`titleMedium`** heading above the paper card (not `FinkoPaperCard.title`) | Spending breakdown (`FinkoDonutWithSideLegend`) |
| **Onboarding projected savings chart** | Stacked column: **all expense** segments (fixed + variable) **sorted by amount** (largest at $0) → **savings** (top), blue shades by size; height fills the projected step (`chartTotalHeight`) | Onboarding projected step (`onboarding_projected_chart.dart`) |

## Core data (rollups)

| Helper | Responsibility | Used on |
|--------|----------------|---------|
| **`finko_account_kind`** | `isLiabilityAccountType`, `netWorthFromAccountsMinor`, `netCashFromAccountsMinor`, `openingBalanceDirectionForAccount` — signed net worth/net cash; opening-balance tx direction for assets vs liabilities | Dashboard (net worth, net cash headline) |

## Accounts & grouping

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Month summary bottom sheets** | `showFinkoCategoryMonthSummarySheet` / `showFinkoAccountMonthSummarySheet`: header + **this month** total + recent transactions + **Edit** (reuses onboarding bottom-sheet editors); invalidates related streams on save | Categories, Accounts |
| **Accounts accordion (cash-flow ordered)** | Sections: checking, credit cards, **net cash** (aggregate, not clickable, **info** icon → calculation dialog); spacer; savings, investments. Row: icon, label, balance, expand. Expanded: one row per account; **animated** open/close (height + chevron). Wrapped in **paper card** on cloud scaffold | Dashboard |
| **Income + fixed + variable accordion** | Three rows (income \| fixed expense \| variable expense), **not clickable** | Spending (`FinkoSpendingIncomeFixedVariableAccordion`) |
| **Income / expense accordion** | Two rows (income \| expense), **not clickable** | Reusable (`FinkoIncomeExpenseAccordion`) |
| **Fixed / variable expense accordion** | Two rows (fixed \| variable), **not clickable** | Reusable (`FinkoFixedVariableExpenseAccordion`) |
| **Account type row** | Icon, label, trailing amount, expand affordance | Accordions |
| **Account line row** | Single account under a section | Accordions |

## Transactions & recurring

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Upcoming transaction card** | Category avatar; name; **bold** amount; footer “days until”; **tap** → `LedgerTransactionEditorSheet` / `openMergedUpcomingEditor` | Dashboard |
| **Open merged upcoming editor** | `openMergedUpcomingEditor` — resolves merged `UpcomingTransaction` to ledger / `upcomingTransactions` / `recurring` and shows `LedgerTransactionEditorSheet` | Dashboard, Recurring |
| **Upcoming “see all” card** | Trailing strip tile: **chevron** + label using **`labelMedium` / `onSurfaceVariant`** (same as metric card footers); tap → **`/recurring`** | Dashboard |
| **Transaction row (compact)** | For lists: icon/avatar, title, subtitle/amount as per screen | Recent, recurring lists, top transactions |
| **Category icon avatar** | `CircleAvatar` + Material icon from `iconKey`; icon tint from `colorArgb` or deterministic theme fallback by `categoryId` (`FinkoCategoryIconAvatar`) | Transaction lists, upcoming strip, recurring |
| **Paper list with “see more”** | List + final row navigates to full list | Dashboard → `/transactions` |
| **Full-width scrollable list** | Standard list layout for many rows | Transactions, categories, accounts |
| **Search + filter bar** | Top search/filter UI | Transactions |
| **Transaction kind filter sheet** | Bottom sheet: All / Standard / Transfer / Adjustment | Transactions |
| **Ledger transaction editor sheet** | Slide-up create/edit stub (`LedgerTransactionEditorSheet.show`); center (+) = create, row tap = edit | App shell, any screen with ledger rows |

## Budgets

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Month paginator field** | Left calendar icon; center **“This month”** (or equivalent); right **prev/next** month — **no date picker popover** | Budgets |
| **Budget progress block** | Labels for spent / left / budgeted + progress bar patterns | Budgets (main spending card), Dashboard monthly budget |
| **Budget compact summary card** | Icon + title + **amount** (compact bold) + **caption** under amount + thin pill progress + **one** footer line (paid / earned); light surface, small elevation | Budgets (Bills & Utilities + Earnings row) (`FinkoBudgetCompactSummaryCard`) |
| **Category avatar with ring progress** | Full **circle track** (`FinkoColors.grayLight`, same as compact budget pill) + **accent arc** (0–1); center **`FinkoCategoryIconAvatar`** when `iconKey` + `categoryId` set, else letter (`FinkoCategoryAvatarRing`). **Budgets** list stacks a small **warning** (tooltip) on the avatar when spend exceeds the row’s budget. | Dashboard monthly budget **2×3** grid, Budgets category rows |
| **Savings projection card** | Two columns: text block + simple column chart (Y from `$0` to short target) | Budgets |

## Auth & settings

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Finko logo** | Square brand mark (`assets/images/app_logo.png`) | Login |
| **Social / provider auth buttons** | Google, Apple per design system | Login |
| **Email/password form** | Fields + submit | Login |
| **Settings row / section** | Theme toggle; external service CTAs | Settings |
| **Messaging connect bottom sheet** | `showOnboardingMessagingChannelSheet` — WhatsApp: phone + OTP. **Telegram:** `TelegramChannelLinkSheet` — phone (dial + national) **or** @username toggle, multi-step (**Next** → spinner + status → open Telegram → Firestore **`_telegramLink/state`** listener → linked ✓ → **Done**); phase content **vertically centered** in the sheet | Onboarding (messaging step), Settings |
| **FinkoThemeModeToggle** | Three icon buttons (light / dark / system) for `ThemePreference` | Settings |
| **Onboarding typewriter header** | Step title animation with reduced-motion + semantics-safe label | Onboarding |
| **Onboarding wizard progress** | Global 9-step progress bar + nav controls | Onboarding |
| **Onboarding segmented toggle** | Single-select pill row for theme, locale, currency (profile step) | Onboarding (`onboarding_ui.dart`) |
| **Onboarding section card** | Icon header + body for review/finalize sections | Onboarding review step |

## Calendar (recurring)

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Two-week mini calendar** | This week on top, next below; **green** dot = income, **blue** (primary) dot = expense, side-by-side if both | Recurring “Coming up” card |

---

## Extraction rule

If you copy the same **row layout** or **card header pattern** more than once, stop and add a widget here first, then replace both call sites.

## Implementation (Flutter)

Shared widgets are implemented under `lib/widgets/` (`finko_*.dart` files grouped by area: `surfaces/`, `layout/`, `metrics/`, `accounts/`, `transactions/`, `budgets/`, `charts/`, `calendar/`, `auth/`). The tabbed **app shell** (bottom nav with center plus action + drawer from top-left settings cog) is `lib/features/shell/presentation/app_shell.dart` with drawer content in `finko_shell_drawer.dart`, wired in `lib/app/app_routes.dart`.

## Revision log

- **2026-05-22** — **Onboarding segmented toggle** / **section card** / **metric tile** for profile pickers, projected savings, and review step.
- **2026-05-13** — **Budgets category rows:** sort by budget target (desc); **over-budget** warning badge on avatar (`budgets_screen.dart`).
- **2026-05-01** — **Messaging connected sheet** / **`telegram_bot_preferences_sheet`**: Telegram **Bot defaults** row for optional **`telegramBotPreferences`**.
- **2026-04-21** — **Messaging OTP bottom sheet** row: Telegram bot-start / deep-link branch + `url_launcher`.
- **2026-04-18** — **Ledger-aware pull refresh** row: `ledgerAwareAppRefreshProvider` for shared `RefreshIndicator` behavior.
- **2026-04-16** — **`FinkoThemeModeToggle`:** three-way theme control on `/settings`.
- **2026-04-16** — **`FinkoPaperCard`:** with **`title == null`**, skip the internal title+`Column` wrapper so **`ListView` / `RefreshIndicator`** children get bounded vertical constraints (fixes `/transactions` viewport layout error). Titled cards unchanged.
- **2026-04-16** — Light scaffold stays **cloud**; accordions/charts/lists that sit on the scaffold use **paper** (`FinkoPaperCard` / existing cards) for white panels. `FinkoPaperCard` applies **InkWell** only when `onTap` is non-null so embedded scroll views behave.
- **2026-04-16** — **Spending** (`/spending`): **stacked paper sections** (strip, accordion, donut in paper, top tx in paper) with **fixed vertical gap** so **cloud** shows between widgets.
