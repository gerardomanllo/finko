# Product tutorial (spotlight walkthrough)

## Purpose

After **setup onboarding** (`/onboarding`), teach the **live shell UI**: bottom navigation, drawer, each tab, stack routes (Categories, Accounts, Budgets, Settings), and the **Agent** pill. Separate from the data-collection onboarding wizard.

## Triggers

| Trigger | When |
|---------|------|
| **Auto** | First visit to `/dashboard` when `users/{uid}.productTourCompleted` is not `true` |
| **Drawer** | **Show tutorial** row — visible for **15 calendar days** after profile `createdAt` (inclusive, profile timezone) |
| **Settings** | **Show tutorial** list tile — always available |

Skip or **Done** on the last step sets `productTourCompleted: true` (Firestore + `SharedPreferences` cache). **Back** walks to the previous step (skipping steps with `skipWhen`). Completing or skipping returns to **dashboard** at scroll offset zero.

## Implementation

| Piece | Location |
|-------|----------|
| Step catalog (24 steps) | `lib/features/product_tutorial/domain/tutorial_catalog.dart` |
| Controller | `lib/features/product_tutorial/application/product_tutorial_controller.dart` |
| Navigation sync | `lib/features/product_tutorial/application/tutorial_navigation.dart` (`syncNavigationForStep`, `resetTourHome`) |
| Tour preview data | `lib/features/product_tutorial/application/tutorial_preview_providers.dart` (in-memory samples while tour is active) |
| Overlay | `lib/features/product_tutorial/presentation/finko_tutorial_overlay.dart` |
| Targets | `TutorialTarget` + `TutorialTargetId` on shell, tabs, drawer, stack screens |
| Host | `ProductTutorialHost` in `lib/app/finko_app.dart` |
| Auto-start | `ProductTutorialAutoStart` on `DashboardScreen` |

## Data

- `users/{uid}.productTourCompleted` (`bool`) — see `docs/data-model.md` §3.

## Revision log

| Date | Change |
|------|--------|
| 2026-05-25 | Fix categories/accounts tour spotlight vertical offset: FAB `bottomInset` padding moved outside `TutorialTarget`; height-capped holes align to target top; tour rows match production card layout. |
| 2026-05-25 | Follow-up: narrower spotlights (first list row, month paginator, donut chart), pill-shaped agent highlight, localized tour preview copy (EN/ES), spending/budgets empty-state previews. |
| 2026-05-25 | Polish: Back navigation, darker scrim, compact anchored tooltip, per-step spotlight fixes, tour-only preview rows for empty analytics, scroll-to-top on exit, stack routes via `goRouterProvider`. |
| 2026-05-25 | Initial product tour: 24 spotlight steps, drawer replay (15 days), Settings replay. |
