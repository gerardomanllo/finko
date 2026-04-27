# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Docs:** [`docs/references/google-sheets-bug-mcp.md`](docs/references/google-sheets-bug-mcp.md) — connect Cursor MCP to Google Form bug responses via **[xing5/mcp-google-sheets](https://github.com/xing5/mcp-google-sheets)** (`uvx`), service account + Drive folder, optional tool filtering.

- **Docs:** [`docs/KNOWN_BUGS.md`](docs/KNOWN_BUGS.md) — living triage list for open **Finko (Responses)** sheet rows (Status ≠ Done / Not a bug), with **Discussed fix** and **Ready to fix** fields.

- **Onboarding:** **Main currency** picker on profile; always-on **Cash** account (`type: cash`, localized name, editable currency and **starting balance**, not deletable); **credit card total credit line**; **Automatic** theme label for system preference; **stacked projected savings** chart (fills step height; blue expense bands; savings on top in green/red); expanded **color/icon dropdowns** (overlay-safe rows); **Remind me later** advances the flow; recurring income **prefills** zero income budgets using monthly/biweekly/weekly multipliers (single state update when opening budgets so fields stay in sync). Firestore accounts may include **`creditLimitMinor`**, **`isSystem`**, and **`cash`** type (see `docs/data-model.md`).

- **Telegram messaging:** Cloud Function **`telegramWebhook`** (Telegram `secret_token` + `/start link_<token>`) binds **`chat_id`** and writes **`integrations.telegram`** in one transaction; **no Telegram OTP**. Flutter link sheet uses **`tg://` / `t.me`** when **`needsBotStart`** is returned; **`disconnectMessagingIntegration`** clears link state and profile integration. Firestore **`telegramLinkTokens`** + **`users/{uid}/_telegramLink`** (rules: client deny-all on token writes).

### Changed

- **Onboarding — projected savings chart:** **all** expense rows (fixed + each variable) are **sorted by budget** so the **largest** sits on the **$0** axis and the stack rises to **projected savings** at the top (expected income); blue shades by stack position.

- **Onboarding:** **Recurring income** edits (amount or cadence) **re-sync** the matching **income category budget** to the monthly-equivalent minor amount, not only on the first visit to the budgets step.

- **Onboarding — color / icon pickers:** the account **color** dropdown shows **named colors** (EN/ES, e.g. "Sky blue" / "Azul cielo") instead of hex codes; account and category **icon** dropdowns show **localized labels** (EN/ES, e.g. "Wallet" / "Cartera") instead of raw internal keys. The saved ARGB / icon key are unchanged.

- **Telegram linking UX:** onboarding/settings sheet uses a **multi-step** flow (phone dial + national number **or** @username, **Next**, progress copy, **Open Telegram**, real-time **`_telegramLink/state`** listener, success checkmark, then OTP). **`kDebugMode`** shows a scrollable **debug trace**; Firestore rules allow **read** of `users/{uid}/_telegramLink` for the owner.

- **UI:** modal bottom sheets (transaction editor, filters, onboarding editors, messaging, month summaries) use **nearly full height** via a shared helper (keyboard-aware, respects the **status-bar inset**, and leaves a **small peek** above the sheet so underlying UI stays visible) instead of short intrinsic or ~82% caps. **Add/edit account** and **add/edit category** sheets use **`useSafeArea` + drag handle** on `showModalBottomSheet` (same as the transaction editor) so they are not edge-to-edge under the status bar. **Category / account month-detail** summary sheets do the same (modal `useSafeArea`, no duplicate inner `SafeArea`).

### Fixed

- **Telegram deep link handoff:** the link sheet tries **`tg://resolve?domain=…&start=…`** before **`https://t.me/…`** so the `start` payload is not dropped by the OS; iOS **`LSApplicationQueriesSchemes`** (`tg`) and Android **`<queries>`** for `tg` / `t.me` support `url_launcher`. Webhook accepts **`/start@BotUsername link_…`** when Telegram sends that command form.

- **Telegram deep link:** link tokens are **hex-only** (safer for `?start=`), live **24h**, **`TELEGRAM_BOT_USERNAME`** strips a leading **`@`** (broken `t.me` URL otherwise). Webhook uses a **Firestore transaction** to bind `chat_id` and mark the token used atomically, and treats **repeat `/start`** for the same chat as **idempotent** success.

- **Ledger / accounts:** **liability** account types (`creditCard`, `loan`, `mortgage`) now use **positive balance = amount owed**; Cloud Functions **`applyAccountDelta`** applies transaction direction using account **`type`**. **Opening-balance** adjustments use inverted **`in`/`out`** for liabilities vs assets. **Net worth** and **net cash** on the dashboard use **signed** sums (subtract liabilities). Existing Firestore data: run the one-time migration in [`docs/references/liability-balance-migration.md`](docs/references/liability-balance-migration.md) per environment after deploy.

- **Categories / Accounts:** after a successful **cascade delete** from the summary **Edit** sheet, the app **closes** the editor and summary bottom sheets so you return to the list.

- **Transactions:** create/edit sheet shows the **account currency** as a **suffix** on amount fields (updates when the account or transfer from/to selection changes).

- **Firestore rules:** transaction **updates** use an **allowlisted `affectedKeys` check** so client edits no longer hit **`permission-denied`** when server aggregate fields are present on the document.

- **Tooling:** `.vscode/launch.json` lists **mobile** (shared iOS/Android), **Web**, and **desktop** debug targets with the right `--flavor` only where Flutter supports it; `.vscode/extensions.json` recommends the Dart extension; `docs/references/README.md` explains Cursor/VS Code usage and why `pubspec` omits `default-flavor` (it breaks `flutter run -d macos` without matching Xcode schemes).

- **Accounts:** editing from the account **summary** sheet only updates **name**, **icon**, and **color**; **account type** and **currency** are shown read-only and are not changed in Firestore (preserves `includeInNetCash` as stored).

- **Accounts:** **Add account** opening-balance adjustment uses **profile calendar “today”** (`todayYyyyMmDdProvider`) passed into `createAccount`, not UTC date, so the ledger row lands on the correct calendar day for the user.

### Added

- **Ledger sync / pull-to-refresh:** Firestore **`users/{uid}.ledgerSourcesLastChangedAt`** and **`aggregateLastCompletedAt`** (server-only; rules-enforced) updated by Cloud Functions; app-wide **`ledgerAwareAppRefreshProvider`** throttles refresh, reads flags from the server, always runs **`materializeDueUpcoming`**, conditionally runs **`reconcileDeferredLedgerForUser`**, then invalidates one canonical set of aggregate-backed Riverpod providers (dashboard, recurring, transactions, spending windows, etc.).

- **Ledger:** every transaction row requires **`categoryId`**; transfer legs use reserved **`ledger-transfer`** category (created at onboarding / ensured on first transfer). **Cross-currency transfers** collect **two amounts** (per leg). **Cascade delete** for categories and accounts (with confirmation counts) removes related transactions, recurring, upcoming, and budget keys.

- **Settings (`/settings`):** three-way **color theme** toggle (icons) with Firestore `themePreference` + app-wide sync from profile; **Manage your plan** stub (disabled, “Coming soon”); **WhatsApp** / **Telegram** rows reusing onboarding OTP bottom sheet when not linked, connected-details sheet + confirm disconnect when linked (`UserSettingsWriter` for theme, **`disconnectMessagingIntegration`** callable for messaging disconnect, `ProfileThemeSyncListener`, `FinkoThemeModeToggle`).

- **Categories (`/categories`) & Accounts (`/accounts`):** paper lists with **icons**; categories grouped income/expense; accounts grouped by type (dashboard order). Row tap opens a **summary bottom sheet** (this month + recent transactions; accounts show **net** in main currency from ledger). **Edit** opens the same **slide-up editors** as onboarding (categories; accounts use **metadata-only** mode—no starting balance). Firestore: `updateCategory`, `updateAccountMetadata`; `FinkoAccount` includes **`iconKey`** / **`colorArgb`**. **Add** uses a **bottom-center floating extended FAB** (tonal) on both routes.

- **Dashboard — net cash:** **info** icon on the net cash row in the accounts accordion opens a localized dialog explaining how net cash is calculated (`FinkoCashFlowAccountsAccordion`).

- **Spending (`/spending`):** period **pill + horizontal period cards** (ascending, default right-most) driven by **`todayYyyyMmDdProvider`**; **`monthlyTotals`** merge + **week** day sums for mini bars; **fixed vs variable** accordion using category **`fixed-expenses`**; **thin donut** with **right-side legend** and **top 4 outflows** from **`transactions`** in range (`watchTransactionsForDateRange` / `transactionsForDateRangeStreamProvider`); **`mainCurrency`** from profile. Helpers in `lib/core/spending/`, providers in `lib/features/spending/presentation/spending_providers.dart`.

- **Docs:** [`docs/ledger-aggregations-and-ui-flow.md`](docs/ledger-aggregations-and-ui-flow.md) — canonical **functional** flow from `transactions` to Firestore aggregates and dashboard numbers, with **traceability** to Jest (`functions/test/`) and Dart tests; mermaid charts for CF deltas and UI derivation paths. Linked from [`docs/data-contract.md`](docs/data-contract.md) §12 and [`docs/README.md`](docs/README.md).

- **Tests:** [`test/core/monthly_totals_as_of_date_test.dart`](test/core/monthly_totals_as_of_date_test.dart) for `expenseMinorMainThroughDate` and `byCategoryMinorMainThroughDate` (MTD expense and category ring scaling).

- **Transactions screen:** paginated ledger (`fetchTransactionsPage`, 20 per page, infinite scroll), debounced search, **LedgerTransactionKind** filter ring, background “full history” page fetch when search has no match in loaded rows, pull-to-refresh; shell **New** opens ledger editor slide-up. Docs: `docs/transactions.md`, `docs/data-contract.md` §9.

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

- **Category / account summary sheets:** Per-row amounts and the **account month net** now use **`amountMinorMain`** when present, else **`amountMinor`** only if the row currency matches **main currency** (same rule as spending aggregates / transactions list); foreign rows without a main stamp show **native** signed totals and are excluded from the main-currency month sum.

- **Transactions (`/transactions`):** ledger **paper list** is **full width** (removed body-wide horizontal padding); **search + filter** row keeps **16** gutters; each transaction row uses **16** horizontal inset so content does not touch screen edges.

- **Money display:** amounts from **`formatMinorUnits`** / **`formatMinorUnitsWithCode`** now include a **`$`** prefix (e.g. `$1,234.56`, `$1,234.56 MXN` for secondary-currency rows).

- **Onboarding commit:** `toCommitPayload` now sends **`profile.mainCurrency`** (from the first account’s ISO code, uppercased). On **`OnboardingStep.completion`**, the app **invalidates** profile, accounts, categories, recurring, upcoming, and relevant **`monthlyTotals`** stream providers before **`/dashboard`** so post-commit data (including **`budgets`**) is not stale.

- **Firestore — budgets:** Category targets are canonical on **`users/{uid}.budgets`** (same map for every month), not on **`monthlyTotals/{yyyy-mm}`**. **`commitOnboarding`** merges budgets into the profile doc; ledger **`defaultMonthly`** no longer seeds **`budgets`**. Flutter: **`UserProfile.budgets`**, dashboard + `/budgets` read **`userProfileStreamProvider`** for targets vs **`monthlyTotals`** actuals. Docs: **`docs/data-model.md`**, **`docs/data-contract.md`**, **`docs/budgets.md`**, **`docs/onboarding.md`**, **`docs/ledger-aggregations-and-ui-flow.md`**.

- **Budgets (`/budgets`):** **Earnings** compact card uses **X** = sum of month budget targets on **income** Firestore categories (`incomeCategoryBudgetTargetMinor`) vs **Y** = **`incomeMinorMain`**; small tiles use **smaller type** with **amount above** “left to pay” / “to earn” captions. **Gastos por categoría** list shows **expense** budget rows only. Docs: **`docs/budgets.md`**, **`docs/components-inventory.md`**.

- **Spending:** period strip lists **only periods that have at least one transaction** and **auto-scrolls to the right** when the period pill changes; **single accordion** (income + fixed + variable); donut + legend **centered horizontally**; donut ring **thinner**; largest-transaction list uses **`amountMinorMain`** with **`amountMinor`** fallback when `currency` matches **`mainCurrency`**.

- **Cloud Functions — ledger aggregate:** Rows with **`transactionDate` after** the user’s calendar today **do not** update **`accounts`** / **`monthlyTotals`** until applied; they set **`aggregateDeferred: true`**. Callable **`reconcileDeferredLedgerForUser`** applies due rows; the **Flutter app** invokes it on lifecycle (once per profile calendar day, SharedPreferences) and on **every** dashboard/recurring pull-to-refresh—**no** scheduled job. See `docs/data-model.md` §4, `lib/core/upcoming/deferred_ledger_reconcile_service.dart`.

- **Dashboard:** “Recent” lists only transactions on or before profile today; “Próximos” merges scheduled upcoming rows after today with active recurring rules not yet represented there and **future-dated ledger (`transactions/`) rows** so editor-scheduled expenses appear; monthly expense, budget teaser, and net-worth sparkline use **month-to-date** / profile-calendar bounds so future-dated ledger rows do not affect aggregates.

- Transactions filter: **bottom sheet** with explicit type options instead of cycling on the filter button.
- **Ledger create/edit:** unified [`LedgerTransactionEditorSheet`](lib/widgets/transactions/ledger_transaction_editor_sheet.dart) slide-up (no `/transactions/new` route); center nav = create, ledger row tap on Dashboard / Spending / Transactions = edit.

- [`docs/dashboard.md`](docs/dashboard.md): documented current Firestore-backed dashboard (providers, `monthlyTotals` usage, pull-to-refresh, remaining stubs); added revision log. [`docs/data-contract.md`](docs/data-contract.md) §5 and [`docs/data-model.md`](docs/data-model.md) §7 updated for dashboard subscriptions and budget map shapes. [`docs/README.md`](docs/README.md): data section aligned with live backend.

- Documented ledger aggregate **catch-up**, **`aggregateApplied`**, optional **`reload`** fields, and embedded **`days`** maps in [`docs/data-model.md`](docs/data-model.md) §4.1a, [`docs/data-contract.md`](docs/data-contract.md) §12, [`docs/backend-strategy.md`](docs/backend-strategy.md) §4.2, and [`docs/README.md`](docs/README.md) backend index.

### Fixed

- **`FinkoPaperCard`:** when `title` is null, render **`Padding` → `child` only** (no wrapping `Column(mainAxisSize: min)`), so scrollables such as the **Transactions** `ListView` inside `RefreshIndicator` receive a bounded height and no longer throw **Vertical viewport was given unbounded height**.

- **Firestore rules:** `users/{uid}/transactions` create/update may not add or change server-owned keys (`aggregateApplied`, `aggregateDeferred`, `reload`, `aggregateReload`, `amountMinorMain`, `fxRateDateUsed`); aligns with [`docs/data-model.md`](docs/data-model.md) §11. **Flutter CI** uses **Node 24** for Functions Jest to match [`functions/package.json`](functions/package.json) `engines`.

- **Firestore rules — `users/{uid}` profile:** split **create** and **update** so **create** does not call `diff(resource.data)` (no existing document / **`resource`**); **create** rejects payloads that include **`onboardingCompleted`** or **`integrations`**; **update** rejects any **addition, removal, or change** to those keys via **`diff(...).affectedKeys()`** (not **`changedKeys()`**, which misses first-time **adds**). See [`docs/data-model.md`](docs/data-model.md) §11.

- **Ledger delete/update:** Monetary reversal runs only when `snapshotBalancesIncludedThisRow` (`functions/src/aggregateLedger.ts`) — skip if **`aggregateDeferred`** (pending future) **or** explicit **`aggregateApplied: false`** (aggregate never applied; any date). Fixes **`accounts`** drifting when **`monthlyTotals`/NW** did not get the matching +1. See `docs/data-model.md` §4.1a.

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
