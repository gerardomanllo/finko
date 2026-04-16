# References (agents & humans)

Use this folder for **stable pointers** that agents should read when touching a specific area:

| Topic | Suggested content |
|-------|-------------------|
| **Firebase** | Links to console project, `firebase.json` notes, which Hosting site is prod vs dev |
| **Firebase Auth manual setup** | [`firebase-auth-manual-setup.md`](firebase-auth-manual-setup.md) - provider enablement, Android SHA-1/SHA-256, Apple Services ID + OAuth code flow + callback URL, forgot-password template checklist |
| **Auth next steps** | [`auth-next-steps.md`](auth-next-steps.md) - rolling checklist of remaining auth tasks and blockers (including Apple login dependency on Apple Developer account) |
| **Stripe + Firebase (memberships)** | [Invertase “Run Payments with Stripe” extension](https://extensions.dev/extensions/invertase/firestore-stripe-payments) — Firestore sync + optional Auth custom claims; [invertase/stripe-firebase-extensions](https://github.com/invertase/stripe-firebase-extensions) (source, README, POSTINSTALL). [Stripe: Subscriptions](https://docs.stripe.com/subscriptions), [Checkout](https://docs.stripe.com/payments/checkout), [Customer Portal](https://docs.stripe.com/customer-management), [Webhooks (signing)](https://docs.stripe.com/webhooks/signatures). Product doc: [`../membership-and-monetization.md`](../membership-and-monetization.md). |
| **Design** | Figma or asset URLs (if any) |
| **APIs** | Third-party docs for providers (Google/Apple sign-in, messaging APIs) |

Keep entries **short**; prefer linking out over pasting large blobs. Update when environments or URLs change.

## Flutter app stack

Decisions for client code. **Detail:** `.cursor/rules/finko-flutter-architecture.mdc`.

| Concern | Choice | When to add to `pubspec.yaml` |
|--------|--------|-------------------------------|
| **Routing** | **`go_router`** | Before implementing shell, nested routes, or deep links. |
| **State** | **Riverpod** (`flutter_riverpod`) | Before app-wide or feature providers; aligns with `docs/data-contract.md` (`AsyncValue`, streams). |
| **Localization** | **gen-l10n** + **`flutter_localizations`** + **`intl`** | When adding ARBs and replacing hardcoded user-visible strings (see `docs/language-and-localization.md`). |

- **`lib/` layout:** Prefer `lib/features/<feature>/`, `lib/core/`, and `lib/widgets/` from the first shell or primary screen; keep only entrypoints and generated Firebase options beside them at `lib/` root where needed.

**Firebase:** `firebase_core` may initialize at bootstrap (dev/prod); **stub or mock repositories** until a task integrates Firestore/API—initialization is environment wiring, not product data.

## Flutter flavors (dev/prod)

- Environments:
  - `dev` -> Firebase project `finkoappmx-dev`
  - `prod` -> Firebase project `finkoappmx`
- Dart entrypoints:
  - `lib/main_dev.dart`
  - `lib/main_prod.dart`
- Firebase options:
  - `lib/firebase_options_dev.dart`
  - `lib/firebase_options_prod.dart`
- Native Firebase files:
  - Android dev: `android/app/src/dev/google-services.json`
  - Android prod: `android/app/src/prod/google-services.json`
  - iOS dev: `ios/config/dev/GoogleService-Info.plist`
  - iOS prod: `ios/config/prod/GoogleService-Info.plist`

### Run commands

- Android dev: `flutter run --flavor dev -t lib/main_dev.dart`
- Android prod: `flutter run --flavor prod -t lib/main_prod.dart`
- iOS dev: `flutter run --flavor dev -t lib/main_dev.dart`
- iOS prod: `flutter run --flavor prod -t lib/main_prod.dart`
- Web dev: `flutter run -d chrome -t lib/main_dev.dart`
- Web prod-like: `flutter run -d chrome --release -t lib/main_prod.dart`
