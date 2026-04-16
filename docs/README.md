# Finko — screen documentation (frontend, iteration 1)

Personal finance tracker (Flutter: iOS, Android, Web). Backend is Firebase later; these specs describe **UI, navigation, and reusable building blocks** only.

## How to use this folder (agents & humans)

1. Read **`components-inventory.md`** before adding widgets — prefer shared primitives over one-off copies.
2. Implement or change a route using the matching **`*.md` screen doc** as the source of truth for layout and behavior.
3. If a pattern appears on **two or more screens**, add or update an entry in **`components-inventory.md`** instead of duplicating markup.

## Screen index

| Doc | Route(s) | Notes |
|-----|----------|--------|
| [splash.md](splash.md) | Initial / bootstrap | Standard splash |
| [language-and-localization.md](language-and-localization.md) | — | Spanish (default) + English; ARB; profile `locale` |
| [login.md](login.md) | `/login` | Email/password + Google + Apple |
| [onboarding.md](onboarding.md) | `/onboarding` | Typeform-style wizard → `/dashboard` |
| [shell-navigation.md](shell-navigation.md) | App shell | Bottom nav + center plus action + drawer from settings cog |
| [dashboard.md](dashboard.md) | `/dashboard` | Main dashboard |
| [recurring.md](recurring.md) | `/recurring` | Calendar + due soon / later |
| [spending.md](spending.md) | `/spending` | Period pills + cards + accordion + pie |
| [transactions.md](transactions.md) | `/transactions` | Search + full list |
| [budgets.md](budgets.md) | `/budgets` | Month pager + budget cards |
| [categories.md](categories.md) | `/categories` | Drawer / full list |
| [accounts.md](accounts.md) | `/accounts` | List by type; linked from dashboard metric |
| [settings.md](settings.md) | `/settings` | Theme + messaging CTAs |

## Cross-cutting rules

- **Languages**: **[language-and-localization.md](language-and-localization.md)** — Spanish (default) and English for the full app; ARB / l10n and profile `locale`.
- **DRY**: Shared visuals (paper surfaces, accordions, metric cards, lists) live in reusable widgets; see inventory.
- **Precision**: Screen docs define **structure, ordering, and navigation**; copy and exact styling follow app theme.
- **Data**: Stub/mock until Firebase; docs call out **data shape** only where it clarifies UI.

## Backend (living)

- **[analytics.md](analytics.md)** — Firebase Analytics is **required for product metrics**; not automatic beyond SDK integration; align with dev/prod Firebase projects.
- **[backend-strategy.md](backend-strategy.md)** — product/domain understanding, **aggregation** approach, Firebase service choices (scalability, cost, performance). Update the revision log when this evolves.
- **[data-model.md](data-model.md)** — Firestore paths, fields, **`monthlyTotals`** embedding, entities (transactions, accounts, categories, budgets, recurring).
- **[data-contract.md](data-contract.md)** — how **repositories + Riverpod + `snapshots()`** feed widgets; **real-time only** (no nightly batch for core data); screen→subscription map.
- **[membership-and-monetization.md](membership-and-monetization.md)** — freemium UX patterns (paywalls, CTAs, upsells), **entitlements** and gating, **Stripe + Firebase** (extension vs custom webhooks). Align subscription fields with `data-model.md` when implemented.

## Project metadata

- **Changelog**: Root [`CHANGELOG.md`](../CHANGELOG.md) — update for user-visible or notable changes.
- **External references**: [`docs/references/README.md`](references/README.md) — stable links for Firebase, design, APIs, **Flutter app stack** (routing, state, l10n deps, `lib/` layout).
- **Engineering standards**: `.cursor/rules/` (environments, CI, Firebase, DB, Flutter, testing, docs).
