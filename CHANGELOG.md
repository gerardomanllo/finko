# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **App shell** (`StatefulShellRoute`): bottom navigation for Dashboard, Recurring, Spending, and Transactions; **More** opens the drawer (Categories, Accounts, Settings). Shared UI primitives under `lib/widgets/` (paper surfaces, metric carousel + sparkline, cash-flow and income/expense accordions, donut chart, budget month pager, two-week calendar, search bar, login sections) and feature screens aligned with `docs/components-inventory.md`. Dependency: **`fl_chart`**. `monthlyTotalsForMonthStreamProvider` for month-scoped budget views.
- [`docs/references/README.md`](docs/references/README.md) — **Flutter app stack** table (`go_router`, Riverpod, l10n deps), `lib/` layout guidance, Firebase init vs stub data.
- [`.cursor/rules/finko-flutter-architecture.mdc`](.cursor/rules/finko-flutter-architecture.mdc) — locked **go_router**, dependency milestones, greenfield `lib/` layout note.
- [`.cursor/skills/finko-frontend/SKILL.md`](.cursor/skills/finko-frontend/SKILL.md) — clarify Firebase bootstrap vs stubbed product data.
- [`docs/language-and-localization.md`](docs/language-and-localization.md) — first-time **gen-l10n** bootstrap checklist; Spanish (default) and English for the full app; ARB/l10n and profile `locale` alignment.
- [`docs/data-model.md`](docs/data-model.md) and [`docs/data-contract.md`](docs/data-contract.md) — resolved field conventions (direction, two-leg transfers, `transactionDate`/`loadedAt`, multi-currency + `forexRates` + [Frankfurter](https://frankfurter.dev/), budgets in `monthlyTotals`, `upcomingTransactions` materialization); daily FX job allowed, not aggregate cron.
- [`docs/backend-strategy.md`](docs/backend-strategy.md) — aggregation strategy and Firebase backend recommendations (living document).
- Initial project documentation under `docs/` and engineering rules under `.cursor/rules/`.
- GitHub Actions workflow `.github/workflows/flutter.yml` (format, analyze, test).
- Dashboard route `/dashboard` only; login uses email + Google + Apple; Settings documents WhatsApp/Telegram as messaging CTAs (not auth).
