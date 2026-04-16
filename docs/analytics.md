# Analytics (planned)

We **intend to use Firebase Analytics** for product and funnel visibility (screens, key actions, conversion). This is a **deliberate product requirement**, not something Firebase turns on without app work.

## When to implement (sequencing)

**Add Analytics after the main screens and flows exist and behave correctly**—not in parallel with first-pass UI work.

Rationale:

- Routes, navigation, and copy stabilize first, so we avoid renaming events or logging the wrong surfaces mid-refactor.
- It is easier to choose **meaningful** screen and funnel events once the real user journeys are visible end-to-end (including which steps matter for conversion vs noise).
- Agents and humans can apply judgment on **where** instrumentation pays off instead of scattering events early.

This does **not** block other Firebase work (Auth, Firestore, etc.); it only defers the **`firebase_analytics`** integration and custom `logEvent` / screen wiring until the UI foundation is in place.

## What Firebase provides vs what we must build

- **Console & reporting**: Firebase projects include Analytics in the console once the SDK is integrated and data flows.
- **Not automatic in Flutter**: Having `firebase_core` and flavor wiring is **not** enough. We still need the **`firebase_analytics`** package (and initialization after `Firebase.initializeApp`).
- **Automatic vs custom events**: Some **automatic** events apply once Analytics is integrated; **business-specific** events (onboarding steps, paywall views, subscription outcomes, etc.) must be **logged explicitly** in code with a consistent naming scheme.

## Environment alignment

- **Dev** and **prod** use separate Firebase projects (see [`references/README.md`](references/README.md)). Analytics data should stay in the matching project per build flavor so staging traffic does not pollute production metrics.

## Implementation checklist (after screens are stable)

1. Add `firebase_analytics` and wire it after Firebase init in the shared bootstrap (`lib/main_common.dart` or a small analytics service).
2. Define a **minimal event taxonomy** (event names, parameters) and document it here or in `data-contract.md` if events tie to user journeys.
3. Respect privacy and store policies: document consent/ATT if we add them; avoid sending PII in event parameters.

## References

- [Firebase Analytics for Flutter](https://firebase.google.com/docs/analytics/get-started?platform=flutter)
- Flavor and Firebase project mapping: [`references/README.md`](references/README.md)
