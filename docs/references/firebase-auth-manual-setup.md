# Firebase Auth manual setup (Google + Apple + Password reset)

This runbook documents the manual steps required outside Flutter code for the Finko login stack.

## Scope

- Email/password sign-in and account creation
- Google sign-in
- Apple sign-in
- Forgot-password reset emails

## Environment mapping

Use the right project per flavor (see `docs/references/README.md`):

- `dev` -> `finkoappmx-dev`
- `prod` -> `finkoappmx`

Never mix prod app IDs/files with dev Firebase resources.

## 1) Firebase Console -> Authentication -> Sign-in method

Enable providers in each environment project:

- Email/Password: enabled
- Google: enabled
- Apple: enabled

Forgot password uses Firebase Auth email templates and does not require a separate provider toggle once Email/Password is enabled.

## 2) Google sign-in manual steps

### Android release fingerprints (required for release Google auth)

1. Get SHA-1 and SHA-256 for the signing key used by your release pipeline.
2. Firebase Console -> Project settings -> Android app -> add SHA certificates.
3. Download/update `google-services.json` if Firebase asks for refreshed config.
4. Confirm flavor file placement:
   - `android/app/src/dev/google-services.json`
   - `android/app/src/prod/google-services.json`

If this step is missing, Google auth can work in debug and fail in release.

### iOS Google config

1. Verify correct `GoogleService-Info.plist` per flavor:
   - `ios/config/dev/GoogleService-Info.plist`
   - `ios/config/prod/GoogleService-Info.plist`
2. Ensure URL scheme/reversed client ID setup is present in iOS project settings.

### Web Google config

1. Add app hosts to authorized domains in Firebase Auth settings.
2. Validate popup flow in web build (`signInWithPopup` path).

## 3) Apple sign-in manual steps

Firebase Apple provider asks for:

- Services ID
- OAuth code flow config (Apple key data)
- Authorization callback URL

How they connect:

1. In Apple Developer account, create/configure Sign in with Apple for your app identifiers.
2. Create a Services ID for web/OAuth style flows.
3. Configure return URLs in Apple using the exact callback URL shown by Firebase.
4. Provide Firebase with the required Apple credentials for OAuth code flow.
5. In iOS project, enable Sign in with Apple capability for the app target.

If callback URL or Services ID does not match exactly, Apple login usually fails after consent.

## 4) Password reset (forgot password) setup

1. Firebase Console -> Authentication -> Templates -> Password reset:
   - Set sender name
   - Verify support email/sender
   - Localize content as needed
2. Ensure app/web authorized domains include links users will open.
3. Test reset delivery and completion in both dev and prod projects.

## 5) Verification checklist (per environment)

- [ ] Email/password login works
- [ ] Create account works
- [ ] Forgot password email is sent and delivered
- [ ] Google login works on web
- [ ] Google login works on Android release build
- [ ] Google login works on iOS
- [ ] Apple login works on iOS
- [ ] Apple login works on web (if supported for target browsers)
- [ ] Sign-out redirects to `/login` without crash

## Current known status (from latest setup notes)

- [x] Google provider enabled
- [ ] Android release SHA-1/SHA-256 added
- [x] Apple provider enabled
- [ ] Apple Services ID / OAuth code flow fields finalized
- [ ] Apple callback URL registered end-to-end

Update this section whenever manual setup state changes.
