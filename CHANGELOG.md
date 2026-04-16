# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Recurring screen Firestore wiring:** profile-timezone **“today”** (`timezone` package + `todayYyyyMmDdProvider`), `categoriesStreamProvider` and `recurringRulesStreamProvider`, enriched list rows (memo → rule name → category), category icons, error banner with retry, pull-to-refresh with `materializeDueUpcoming`. Cloud Functions: `scheduleNext.ts` (next occurrence + `resolveAsOfYmd`), `materializeDueUpcoming` updates linked **`recurring.nextTransactionDate`**, `commitOnboarding` sets **`recurringRuleId`** and maps onboarding “two paydays” to **`twiceMonthly`**. Docs: `docs/recurring.md`, `docs/data-model.md` §8–9, `docs/data-contract.md` §5/§11, `docs/references/product-todos.md`.
- Dashboard backend wiring: replaced net-worth sparkline stubs with a 30-day `monthlyTotals.days.*.netWorthEodMinorMain` series (forward-fill fallback), added user-profile stream usage for main-currency formatting, and enforced strictly-future upcoming rows on `/dashboard`.
- Upcoming materialization hardening: listener now re-checks on app resume and timezone/profile changes, while the callable service runs once per user/day with timezone-aware payload fallback plus unit coverage for cadence/payload behavior.
- Full onboarding v1 foundation: 9-step wizard at `/onboarding` with Riverpod draft state, step validation/gating, typewriter header, projected-savings step math, messaging OTP hooks, and commit-to-dashboard completion flow.
- Firebase Functions onboarding backend: `commitOnboarding` callable (idempotent `requestId`, profile/accounts/categories/budgets/recurring writes, starting-balance adjustment transactions, server-side `onboardingCompleted`) plus `requestMessagingOtp` / `verifyMessagingOtp` callables for trusted messaging integration writes.
- Onboarding tests for projected-savings model math and controller step validation (`test/features/onboarding/*`), plus expanded onboarding localization keys in `app_es.arb` and `app_en.arb`.

- Login/Auth upgrades: forgot-password end-to-end flow on `/login` (localized CTA + success/error feedback via Firebase Auth `sendPasswordResetEmail`), keyboard-safe login form polish (`AutofillGroup`, submit actions, inset-aware scrolling), and Google provider button icon treatment.
- Firebase/Auth operator runbook: [`docs/references/firebase-auth-manual-setup.md`](docs/references/firebase-auth-manual-setup.md) covering Google release SHA-1/SHA-256, Apple Services ID + OAuth code flow + callback URL, and password reset template checks.
- Login widget tests for core auth affordances and forgot-password interactions (`test/features/auth/login_screen_test.dart`) using hermetic provider overrides.

### Changed

- [`docs/dashboard.md`](docs/dashboard.md): documented current Firestore-backed dashboard (providers, `monthlyTotals` usage, pull-to-refresh, remaining stubs); added revision log. [`docs/data-contract.md`](docs/data-contract.md) §5 and [`docs/data-model.md`](docs/data-model.md) §7 updated for dashboard subscriptions and budget map shapes. [`docs/README.md`](docs/README.md): data section aligned with live backend.

- Documented ledger aggregate **catch-up**, **`aggregateApplied`**, optional **`reload`** fields, and embedded **`days`** maps in [`docs/data-model.md`](docs/data-model.md) §4.1a, [`docs/data-contract.md`](docs/data-contract.md) §12, [`docs/backend-strategy.md`](docs/backend-strategy.md) §4.2, and [`docs/README.md`](docs/README.md) backend index.

### Fixed

- Ledger aggregation: `onLedgerTransactionWritten` now runs a one-shot catch-up when money fields are unchanged but `aggregateApplied` is still missing (so toggling a reload flag re-applies totals instead of netting zero), coerces `amountMinor` from Firestore into a finite int, writes `aggregateApplied` on the transaction after a successful aggregate, and `commitOnboarding` now persists `profile.mainCurrency` (defaulting to MXN when absent).

- Post-logout stability: hardened locale subscription error handling during auth transitions and made Google local sign-out cleanup non-blocking so Firebase sign-out/redirect completes reliably.

- Global Material 3 light theme with Finko palette tokens (`#173fba`, `#3e6ff5`, `#f0f4fe`, `#4d5462`, `#6d727f`, `#d2d5da`) wired through `FinkoTheme` and app-level `MaterialApp.router`.
- Dark-theme refinement pass: semantic income/expense colors, improved progress/list/icon defaults for contrast, and brand-consistent spending chart palette (no hardcoded orange/teal).
- **Splash** route `/splash` as initial cold-start screen (`kMinSplashDuration` + auth/onboarding gate); see `docs/splash.md`.
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
