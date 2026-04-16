# Splash

## Route

- Initial route / bootstrap (exact path follows router config; often `/` or `/splash`).

## Purpose

- Standard splash while the app loads (assets, fonts, auth state check later).

## UI

- Full-screen splash: logo and/or app name per brand.
- No user actions required; transitions away when ready.

## Navigation

- **Out**: To `/login` (unauthenticated) or main shell (authenticated) — wire when auth exists; for frontend-only, pick one stub destination.

## Reuse

- None beyond global theme/branding.

## Data (frontend phase)

- None; optional timer or `Future` for minimum display time.

## Acceptance

- [ ] Displays on cold start.
- [ ] Does not block forever (stub navigation acceptable).
