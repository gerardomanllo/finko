# Settings

## Route

- `/settings`

## Purpose

- App preferences and optional **messaging channel** setup (not OAuth login).

## UI — stock settings layout

- Standard **settings** page structure (grouped sections / list tiles).

### Appearance

- **Color theme:** three-way control (**Light** / **Dark** / **System**) with icons (`FinkoThemeModeToggle`). Persists to `users/{uid}.themePreference` and applies via `themeModeProvider`; profile stream is mirrored into the app theme in `ProfileThemeSyncListener` (`lib/app/profile_theme_sync_listener.dart`).

### Membership

- **Manage your plan** — opens the user-specific Stripe Customer Portal (or Billing Portal “magic”) link once the backend exposes it.
- Today: **disabled** control with **Coming soon** copy (no URL); when shipped: portal link must be generated **server-side** for authenticated `uid` (single-use URL), then opened by the app; on return, refresh membership state and entitlements.

### Messaging integrations (optional)

- Separate rows (**WhatsApp**, **Telegram**) with **Connected** / **Not connected** from `UserProfile.integrations`.
- **Not connected:** same bottom sheet as onboarding — `showOnboardingMessagingChannelSheet` + `requestMessagingOtp` / `verifyMessagingOtp` Cloud Functions; then refresh profile stream.
- **Connected:** bottom sheet shows identity (`phoneE164` / `@username`) and verified date when present; **Disconnect** → confirm dialog → client merge/removes `integrations.whatsapp` or `integrations.telegram` on `users/{uid}` (empty `integrations` object removed).
- User may connect **one, both, or neither** — do not require both.
- Copy must **not** imply WhatsApp/Telegram are sign-in methods (they are **messaging** integrations only).

## Navigation

- **In**: Drawer → **Settings**.

## Reuse

- Shared settings row / section widgets.

## Data

- `themePreference` on `users/{uid}` (`light` | `dark` | `system`) — client merge on change from Settings.
- Messaging link state: `integrations.whatsapp` / `integrations.telegram` on profile (see `docs/data-model.md`).

## Acceptance

- [x] Theme switch applies globally (`themeModeProvider` + Firestore `themePreference` + profile-driven sync).
- [ ] **Manage your plan** opens a server-generated Stripe portal link (UI placeholder until backend).
- [x] **At least two** distinct CTAs: WhatsApp and Telegram (OTP flow wired; disconnect via Firestore).
- [x] Copy does **not** imply WhatsApp/Telegram are sign-in methods.

## Revision log

- **2026-04-16** — Appearance: icon **three-way theme** toggle + Firestore persistence + `ProfileThemeSyncListener`. Membership: **Manage your plan** disabled with **Coming soon**. Messaging: WhatsApp/Telegram rows, reuse onboarding OTP sheet when not linked, connected-details sheet + confirm disconnect.
