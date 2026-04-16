# Shared components & DRY map

Use these names as **implementation targets** (rename to match `lib/` conventions). When two screens need the same structure, **extract** rather than fork.

## Layout & shell

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **App shell** | `Scaffold` + bottom navigation + center plus action + `Drawer` toggled from top-left settings cog | All main tabs |
| **App drawer** | Header: avatar + name; items: Categories, Accounts, Settings | Shell |
| **Screen scaffold** | Title (and optional actions) consistent with app style | Most routes |

## Surfaces

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Paper card / paper section** | Full-width or inset “paper” surface (elevation, padding) | Dashboard, recurring, spending, transactions, budgets, categories, accounts |
| **Pill toggle group** | Single-select pills (segmented control style) | Spending (`week` / `month` / `quarter` / `year`) |

## Metrics & charts

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Metric carousel card** | Top-left label, large value, top-right period delta; tappable | Dashboard (Net Worth, Monthly expense) |
| **Two-card horizontal carousel** | Swipe/carousel hosting two metric cards | Dashboard |
| **Net worth sparkline / line chart** | ~30 days series inside Net Worth card | Dashboard |
| **Mini income vs expense chart** | Two columns (income \| expense) “graph-ish” per period | Spending (row of vertical period cards) |
| **Donut / ring pie chart** | Colored **ring only**; white center with title + bold total | Spending breakdown |

## Accounts & grouping

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Accounts accordion (cash-flow ordered)** | Sections: checking, credit cards, **net cash** (aggregate, not clickable); spacer; savings, investments. Row: icon, label, balance, expand. Expanded: one row per account | Dashboard |
| **Accounts accordion (income/expense)** | Only income and expense sections; **not clickable** | Spending |
| **Account type row** | Icon, label, trailing amount, expand affordance | Accordions |
| **Account line row** | Single account under a section | Accordions |

## Transactions & recurring

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Upcoming transaction card** | Category avatar; name; **bold** amount; footer “days until” | Dashboard |
| **Transaction row (compact)** | For lists: icon/avatar, title, subtitle/amount as per screen | Recent, recurring lists, top transactions |
| **Paper list with “see more”** | List + final row navigates to full list | Dashboard → `/transactions` |
| **Full-width scrollable list** | Standard list layout for many rows | Transactions, categories, accounts |
| **Search + filter bar** | Top search/filter UI | Transactions |

## Budgets

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Month paginator field** | Left calendar icon; center **“This month”** (or equivalent); right **prev/next** month — **no date picker popover** | Budgets |
| **Budget progress block** | Labels for spent / left / budgeted + progress bar patterns | Budgets, Dashboard monthly budget |
| **Category avatar with ring progress** | Circle avatar, white fill, **border as progress** | Dashboard monthly budget (top 6), category budget rows |
| **Savings projection card** | Two columns: text block + simple column chart (Y from `$0` to short target) | Budgets |

## Auth & settings

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Finko logo** | Square brand mark (`assets/images/app_logo.png`) | Login |
| **Social / provider auth buttons** | Google, Apple per design system | Login |
| **Email/password form** | Fields + submit | Login |
| **Settings row / section** | Theme toggle; external service CTAs | Settings |
| **Onboarding typewriter header** | Step title animation with reduced-motion + semantics-safe label | Onboarding |
| **Onboarding wizard progress** | Global 9-step progress bar + nav controls | Onboarding |

## Calendar (recurring)

| Component | Responsibility | Used on |
|-----------|----------------|---------|
| **Two-week mini calendar** | This week on top, next below; **dot** if any tx that day; **green `$`** marker for scheduled **income** days | Recurring “Coming up” card |

---

## Extraction rule

If you copy the same **row layout** or **card header pattern** more than once, stop and add a widget here first, then replace both call sites.

## Implementation (Flutter)

Shared widgets are implemented under `lib/widgets/` (`finko_*.dart` files grouped by area: `surfaces/`, `layout/`, `metrics/`, `accounts/`, `transactions/`, `budgets/`, `charts/`, `calendar/`, `auth/`). The tabbed **app shell** (bottom nav with center plus action + drawer from top-left settings cog) is `lib/features/shell/presentation/app_shell.dart`, wired in `lib/app/app_routes.dart`.
