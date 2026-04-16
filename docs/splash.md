# Splash

## Route

- Initial route / bootstrap (exact path follows router config; often `/` or `/splash`).

## Purpose

- Standard splash while the app loads (assets, fonts, auth state check later).

## UI

- Full-screen splash: logo and/or app name per brand.
- No user actions required; transitions away when ready.

## Navigation

- **Out**: To `/login` (unauthenticated), `/onboarding` (signed in, onboarding incomplete), or `/dashboard` (signed in, onboarding complete) via `resolvePostSplashLocation` in `lib/app/auth_redirect.dart`.

## Reuse

- None beyond global theme/branding.

## Data (frontend phase)

- None; optional timer or `Future` for minimum display time.

## Acceptance

- [x] Displays on cold start.
- [x] Does not block forever (stub navigation acceptable).
