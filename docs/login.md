# Login

## Route

- `/login`

## Purpose

- Sign-in entry point: email/password and third-party providers.

## UI

- **Email + password** fields and primary submit (sign in / sign up — product decision; document chosen behavior in code comments if split later).
- **Provider buttons** (or rows):
  - **Google**
  - **Apple**
- **Note**: WhatsApp is **not** a login provider. Users connect WhatsApp separately (see `/settings`) for messaging-based flows (e.g. sending transactions or querying data via a link they configure).
- Layout: clear hierarchy; keyboard-safe scrolling on small phones and web.

## Navigation

- **In**: From splash when not signed in; deep links TBD.
- **Out**: On success → main shell (default tab `/dashboard`).
- **Forgot password**: triggered from `/login`; sends a reset email and keeps the user on `/login` with localized feedback.

## Reuse

- See **`components-inventory.md`**: email/password form, provider auth buttons.

## Data

- Backed by Firebase Authentication through `AuthRepository`:
  - Email/password sign in
  - Email/password account creation
  - Google provider sign in
  - Apple provider sign in
  - Forgot-password reset email (`sendPasswordResetEmail`)
- Sign-out from authenticated screens returns users to `/login`.

## Acceptance

- [x] All listed auth affordances visible.
- [x] Web + mobile: tap targets and overflow handled.
- [x] Forgot-password flow sends reset emails with localized success/error feedback.
