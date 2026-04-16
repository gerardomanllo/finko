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
- **Out**: On success → main shell (default tab `/dashboard`). Forgot-password flow TBD.

## Reuse

- See **`components-inventory.md`**: email/password form, provider auth buttons.

## Data (frontend phase)

- Stub `onSubmitted` / `onProviderTap` callbacks; no real Firebase until backend phase.

## Acceptance

- [ ] All listed auth affordances visible (implementations may be stubbed).
- [ ] Web + mobile: tap targets and overflow handled.
