# Shell — bottom navigation & drawer

## Routes

- Shell wraps primary destinations; **exact paths** match router (e.g. `/dashboard`, `/recurring`, `/spending`, `/transactions`).

## Purpose

- Persistent **bottom navigation** for the five primary areas.
- **Navigation drawer** for secondary destinations, opened from a **top-left settings cog** in the app bar.

## Bottom navigation — tabs (order)

1. **Dashboard**
2. **Recurring**
3. **New transaction** — prominent center **plus** action (create flow trigger).
4. **Spending**
5. **Transactions**

## App bar action

- **Settings cog** in the top-left acts as the **drawer toggle**.
- No bottom-bar **More** destination.

## Drawer

### Header

- **Avatar** (left or top as per design)
- **User name** (display name)

### Menu items

- **Categories** → `/categories`
- **Accounts** → `/accounts`
- **Settings** → `/settings`

Close drawer on selection or scrim tap.

## Navigation

- Stack routes for detail screens (budgets, accounts from dashboard, etc.) should preserve shell or use nested navigator per project convention — document in router module.

## Reuse

- Single **App shell** widget: `Scaffold` + `bottomNavigationBar` + `Drawer` + optional nested `Navigator`.

## Data (frontend phase)

- Stub user name/avatar.

## Acceptance

- [ ] Five bottom items in this order: Dashboard, Recurring, New transaction (+), Spending, Transactions.
- [ ] Center plus action opens new transaction creation flow.
- [ ] Top-left settings cog toggles drawer.
- [ ] Drawer lists three destinations and navigates correctly.
- [ ] Current tab state visible.
