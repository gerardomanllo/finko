# Shell — bottom navigation & drawer

## Routes

- Shell wraps primary destinations; **exact paths** match router (e.g. `/dashboard`, `/recurring`, `/spending`, `/transactions`).

## Purpose

- Persistent **bottom navigation** for the five primary areas.
- **Navigation drawer** for secondary destinations, opened from a **top-left settings cog** in the app bar.

## Bottom navigation — tabs (order)

1. **Dashboard**
2. **Recurring**
3. **New transaction** — prominent center **plus** action; opens the **ledger transaction editor** bottom sheet (create mode — no route).
4. **Spending**
5. **Transactions**

- **Chrome:** The shell wraps the bar in a `DecoratedBox` with an **upward** `BoxShadow` stack plus a **top hairline** so it reads above scrolling content. (`Material` elevation mostly draws shadow below the bar, which is often off-screen.)

## App bar action

- **Settings cog** in the top-left acts as the **drawer toggle**.
- No bottom-bar **More** destination.

## Drawer

Implementation: [`FinkoShellDrawer`](../lib/features/shell/presentation/finko_shell_drawer.dart) inside [`AppShell`](../lib/features/shell/presentation/app_shell.dart).

### Header

- **Avatar** (initial from display name, or placeholder)
- **User name** — `UserProfile.displayName` when set, else placeholder copy
- **Plan** — stub chip (e.g. free plan) until subscriptions exist

### Month snapshot (drawer body)

- **Net worth** — compact **paper** surface (same vocabulary as dashboard metric cards: `ColorScheme.surface`, label `onSurfaceVariant`, value uses headline style, stub delta in **primary**). Value matches dashboard logic (sparkline EOD when series has non-zero points, else sum from accounts). **Month delta** is stub copy (no real MoM % yet).
- **Income / Expenses / Savings** — three compact cells on the **cloud** / **navy** muted fills used elsewhere (`FinkoColors.cloud` light, `navy700` dark) for the **dashboard month** (`dashboardYearMonthProvider`): income and expense are **month-to-date** via day rollups when the doc matches the current calendar month; **savings rate** is `(income − expense) / income` clamped to 0…1 when income > 0, else em dash.

### Menu items

- **Dashboard** — switches to shell branch 0 with `initialLocation: true` (does not `push` a route)
- **Categories** → `/categories`
- **Accounts** → `/accounts`
- **Show tutorial** — starts the spotlight product tour (see [`product-tutorial.md`](product-tutorial.md)); shown only for the **first 15 calendar days** after profile `createdAt` (profile timezone)
- **Settings** → `/settings`

**Active row** highlights from `GoRouterState.matchedLocation` (e.g. Dashboard only on `/dashboard`, not on other shell tabs).

Close drawer on selection or scrim tap.

## Navigation

- Stack routes for detail screens (budgets, accounts from dashboard, etc.) should preserve shell or use nested navigator per project convention — document in router module.

## Reuse

- Single **App shell** widget: `Scaffold` + `bottomNavigationBar` + `Drawer` + optional nested `Navigator`.

## Data (frontend phase)

- Drawer reads the same **Riverpod** streams as the dashboard for accounts, profile, monthly totals, and net-worth sparkline where applicable. **Plan tier** remains stub UI until billing.

## Pull-to-refresh

- New screens that add **`RefreshIndicator`** (or equivalent “reload remote data”) must call **`ledgerAwareAppRefreshProvider.runPullToRefresh`** so **materialize**, **conditional reconcile**, and **canonical Riverpod invalidation** stay consistent app-wide (see **`data-contract.md` §11**).

## Acceptance

- [ ] Five bottom items in this order: Dashboard, Recurring, New transaction (+), Spending, Transactions.
- [x] Center plus action opens new-transaction **slide-up** ([`LedgerTransactionEditorSheet`](../lib/widgets/transactions/ledger_transaction_editor_sheet.dart)), not a separate route.
- [ ] Top-left settings cog toggles drawer.
- [x] Drawer lists **Dashboard** (shell), **Categories**, **Accounts**, and **Settings**; navigates correctly; highlights the active row when applicable.
- [ ] Current tab state visible.

## Revision log

| Date | Change |
|------|--------|
| 2026-05-25 | **Product tour:** drawer **Show tutorial** row (15 days after `createdAt`); permanent replay in Settings. |
| 2026-05-13 | **Bottom nav lift:** shell applies explicit **upward** shadow + top border around `NavigationBar` (theme nav `elevation: 0`); Material shadow alone was barely visible at the screen edge. Shadow/hairline strengths tuned for visibility without heaviness. |
| 2026-05-13 | **Drawer colors:** net worth block uses **paper** surface + primary accent (like metric cards); stats and nav selection use **cloud** / **navy** tints consistent with bottom nav indicator. |
| 2026-05-13 | **Rich drawer:** profile + plan stub, month snapshot (net worth, MTD income/expense, savings rate), styled menu including **Dashboard** shortcut; implementation in **`finko_shell_drawer.dart`**. |
| 2026-04-18 | **Pull-to-refresh** convention: use **`ledgerAwareAppRefreshProvider`** on any new refresh surface (`data-contract.md` §11). |
