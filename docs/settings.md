# Settings

## Route

- `/settings`

## Purpose

- App preferences and optional **messaging channel** setup (not OAuth login).

## UI — stock settings layout

- Standard **settings** page structure (grouped sections / list tiles).

### Appearance

- **Color theme:** three-way control (**Light** / **Dark** / **System**) with icons (`FinkoThemeModeToggle`). Persists to `users/{uid}.themePreference` and applies via `themeModeProvider`; profile stream is mirrored into the app theme in `ProfileThemeSyncListener` (`lib/app/profile_theme_sync_listener.dart`).

### Net worth (planned)

- **Include secured-asset estimates in net worth** — toggle (persist on `users/{uid}`). When **on** (planned default), net worth includes **equity** from loan/mortgage accounts with collateral estimates; when **off**, use **balance-only** treatment for those accounts. See [`loans-collateral-and-net-worth.md`](loans-collateral-and-net-worth.md).

### Membership

- **Manage your plan** — opens the user-specific Stripe Customer Portal (or Billing Portal “magic”) link once the backend exposes it.
- Today: **disabled** control with **Coming soon** copy (no URL); when shipped: portal link must be generated **server-side** for authenticated `uid` (single-use URL), then opened by the app; on return, refresh membership state and entitlements.

### Messaging integrations (optional)

- Separate rows (**WhatsApp**, **Telegram**) with **Connected** / **Not connected** from `UserProfile.integrations`.
- **Not connected:** same bottom sheet as onboarding — `showOnboardingMessagingChannelSheet` + `requestMessagingOtp` / `verifyMessagingOtp` Cloud Functions; then refresh profile stream. **Telegram:** multi-step sheet (`TelegramChannelLinkSheet`) — **phone (dial + national) or @username** → **Next** → **Open Telegram** → real-time read of **`users/{uid}/_telegramLink/state`** until `chatId` appears → **Done** (no OTP; profile **`integrations.telegram`** is written by the webhook). **WhatsApp:** still OTP + verify (see [`references/telegram-bot-webhook.md`](references/telegram-bot-webhook.md)).
- **Connected:** bottom sheet shows identity (`phoneE164` / `@username`) and verified date when present; **Disconnect** → confirm dialog → **`disconnectMessagingIntegration`** callable (removes `integrations.*` and, for Telegram, server-only link state under `users/{uid}/_telegramLink`).
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
- [x] **At least two** distinct CTAs: WhatsApp and Telegram (WhatsApp OTP; Telegram magic link; disconnect via **`disconnectMessagingIntegration`** callable).
- [x] Copy does **not** imply WhatsApp/Telegram are sign-in methods.

## Revision log

- **2026-04-22** — Telegram not-connected sheet: **phone/username** toggle, **`_telegramLink`** listener, multi-step copy; **Firestore** rules allow owner **read** on `_telegramLink`.
- **2026-04-21** — Messaging: **Telegram** uses magic link + webhook only (no OTP); **disconnect** uses **`disconnectMessagingIntegration`** callable instead of client-only Firestore merge for integration removal.
- **2026-04-19** — Planned subsection: **net worth** toggle for **secured-asset estimates** (default on when feature ships); pointer to [`loans-collateral-and-net-worth.md`](loans-collateral-and-net-worth.md).
- **2026-04-16** — Appearance: icon **three-way theme** toggle + Firestore persistence + `ProfileThemeSyncListener`. Membership: **Manage your plan** disabled with **Coming soon**. Messaging: WhatsApp/Telegram rows, reuse onboarding OTP sheet when not linked, connected-details sheet + confirm disconnect.
