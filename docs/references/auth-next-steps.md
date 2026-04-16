# Auth next steps

Living checklist of remaining authentication work after the initial Firebase login rollout.

## Current state

- Email/password: working
- Google login: working
- Forgot password: implemented
- Sign out: fixed/stable in current build

## Remaining work

## 1) Apple login enablement (blocked)

Status: blocked  
Blocker: no Apple Developer account yet

What is pending once account exists:

1. Create/prepare Apple Developer team access.
2. Configure Sign in with Apple for app IDs.
3. Create Services ID and set return URL (Firebase callback).
4. Create Apple key for OAuth code flow and upload to Firebase Auth Apple provider.
5. Validate Apple login on real iOS device (dev + prod flavors).

## 2) Android release Google validation

Status: pending

1. Add release SHA-1/SHA-256 for Android app(s) in Firebase project settings.
2. Confirm release-signed build can complete Google login.

## 3) Production hardening (optional but recommended)

Status: pending

1. Verify password reset email template copy + sender for prod.
2. Add/confirm authorized domains for production web targets.
3. Evaluate App Check policy for auth-adjacent APIs.

## References

- [`firebase-auth-manual-setup.md`](firebase-auth-manual-setup.md)
- [`../login.md`](../login.md)
