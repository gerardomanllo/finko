# Shell — bottom navigation & drawer

## Routes

- Shell wraps primary destinations; **exact paths** match router (e.g. `/dashboard`, `/recurring`, `/spending`, `/transactions`).

## Purpose

- Persistent **bottom navigation** for the five primary areas.
- **Navigation drawer** for secondary destinations, opened when user taps **More** on the bottom bar.

## Bottom navigation — tabs (order)

1. **Dashboard**
2. **Recurring**
3. **Spending**
4. **Transactions**
5. **More** — does **not** navigate to its own page; **opens the drawer** (toggle).

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

- [ ] Five bottom items; **More** opens drawer only.
- [ ] Drawer lists three destinations and navigates correctly.
- [ ] Current tab state visible.
