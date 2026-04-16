# Membership, freemium UX, and Stripe + Firebase

This document describes **common industry patterns** for free vs paid tiers, **how to keep gating maintainable**, and **how Stripe fits with Firebase** for Finko. It is product + architecture guidance; when subscription fields land in Firestore, align them with [`data-model.md`](data-model.md) and wire access through [`data-contract.md`](data-contract.md).

---

## 1. Industry patterns (what “standard” usually means)

There is **no single standard**—successful apps mix patterns by category and audience. What *is* common:

| Pattern | Typical use | Notes |
|--------|-------------|--------|
| **Freemium core** | Free tier delivers real value; paid removes limits or adds power features | Reduces churn from “trial ended, nothing works.” |
| **Soft paywall** | User can see *that* a feature exists (preview, blurred row, “locked” badge) and what upgrading unlocks | Good for discovery without feeling hostile. |
| **Hard paywall** | Action blocked until subscribe (e.g. export, 3rd account, automation) | Use for **costly** or **compliance-sensitive** capabilities. |
| **Contextual CTAs** | Upgrade prompts at the moment of intent (hit limit, tap locked feature, Settings → Plan) | Generally outperforms generic banners. |
| **Upsell / cross-sell** | “You’re on Free—add budgets on Pro” when entering a gated surface | Keep copy short; tie to **outcome**, not feature jargon. |
| **Trial (optional)** | Time-boxed full access for new users | Works well if onboarding proves value quickly; document cancellation UX. |

**What to avoid overdoing:** interrupting every session with full-screen paywalls (fatigue), or hiding **basic** trust features (e.g. data export) behind aggressive upsell without clear policy.

---

## 2. Paywalls, CTAs, and upsells—practical guidance for Finko

- **Paywalls (screens or sheets)**  
  Use when the user **chooses** to upgrade (Settings, “Compare plans”) or when they **hit a limit** (clear explanation + single primary action). Prefer **one** primary plan comparison for MVP; add annual/monthly toggle when billing supports it.

- **CTAs (buttons, inline links)**  
  Place **near the gated action** (“Unlock multi-currency,” “Upgrade to add more accounts”). Settings should always expose **Manage subscription** and **Restore purchases** (if applicable).

- **Upsells**  
  Treat as **lightweight** reminders: banner on a gated tab, empty-state on a premium-only list, or a single row in Settings. Refresh copy via Remote Config (see §4) without shipping an app store release for wording tests.

**Consistency:** Use the same product names as the rest of the app (see project UI rules) and localize strings per [`language-and-localization.md`](language-and-localization.md).

---

## 3. Gating logic: easy to change as membership evolves

### 3.1 Single source of truth

- **Billing truth** lives in **Stripe** (subscription status, price, renewal, cancellations).
- The app should **not** trust client-only flags for security-sensitive limits. **Mirror** subscription state into Firebase (Firestore and/or Auth custom claims) using **server-side** updates—typically **Stripe webhooks** processed by **Cloud Functions** (or an official extension; see §5).

### 3.2 Entitlements (recommended abstraction)

Define **entitlements** in code as a small enum or map, e.g. `maxLinkedAccounts`, `exportCsv`, `multiCurrency`, `prioritySupport`. Map **Stripe Price / Product IDs** → **entitlement set** in **one place** (Dart module or JSON loaded at build time).

Benefits:

- UI checks **`entitlements.foo`** instead of string-matching plan names.
- When you add a new price tier, you **only** update the mapping and optionally Remote Config.

### 3.3 Where to configure “what is gated”

| Approach | When to use |
|----------|-------------|
| **Code + constants** | Default for MVP; type-safe; reviewed in PRs. |
| **Firestore `config/planMatrix` (read-only for clients)** | Ops want to flip limits without deploy; still validate in **security rules** that clients cannot self-elevate. |
| **Firebase Remote Config** | Copy, experiment flags, gradual rollouts of **UI** gating; pair with server truth for anything security-relevant. |

**Rule of thumb:** Anything that must not be spoofed (export, API-heavy features) must be **enforced** by **Firestore rules** and/or **Callable Functions** using **server-verified** subscription state.

### 3.4 Riverpod

Expose a **`membershipProvider`** (or `entitlementsProvider`) that:

1. Reads **Firestore** subscription snapshot(s) and/or **refreshes ID token** to read custom claims.
2. Exposes **`AsyncValue<Entitlements>`** for UI.
3. Is **watched** by feature screens; **never** duplicate ad-hoc `isPro` checks scattered without going through this layer (see [`data-contract.md`](data-contract.md) patterns).

---

## 4. Stripe and Firebase integration

### 4.1 Official path used by many Firebase apps: Invertase extension

The **[Run Payments with Stripe](https://extensions.dev/extensions/invertase/firestore-stripe-payments)** extension (maintained by Invertase; historically related to Stripe’s Firebase samples) syncs customers, checkout sessions, and subscriptions to **Firestore**, and can set **Firebase Auth custom claims** for role/access. It expects:

- **Blaze** plan (Cloud Functions, etc.).
- Stripe **restricted API keys** and **webhooks** configured per the extension docs.
- Firestore paths for products/prices and per-user customer data (configurable at install time).

**Web:** The companion **`@invertase/firestore-stripe-payments`** package supports Checkout sessions and listening for subscription updates.

**Flutter:** Flutter clients use **Firebase SDKs** + **Firestore listeners** the same way; Checkout URLs are often opened with **`url_launcher`**. For **native iOS/Android in-app purchase of digital subscriptions**, Apple and Google policies may require **StoreKit / Play Billing** instead of Stripe inside those apps—**confirm with legal/product** before committing to Stripe-only on mobile. Web and many B2B-style apps commonly use Stripe Checkout throughout.

### 4.2 Manage plan (Stripe Customer Portal / “magic link”)

Yes—this is supported with the Invertase flow.

Recommended UX:

1. User taps **Manage your plan** in Settings.
2. App calls a backend path that creates a Stripe Customer Portal session (server-side).
3. Backend returns a **single-use portal URL** (magic link).
4. App opens URL in browser/webview.
5. On return, app refreshes subscription state from Firestore / custom claims.

Implementation notes:

- Invertase provides portal session support via its function flow (`createPortalLink`) and synced customer mapping.
- Never generate portal links on-device with secret keys; create links server-side only.
- Use a configured return URL (app deep link or web route) so users land back in Settings.
- Keep the button visible for all users; adapt copy:
  - Free users: “Manage billing details”.
  - Paid users: “Manage your plan”.

### 4.3 Missing pieces checklist for MVP

To avoid integration gaps, include these items in implementation tasks:

- Settings row: **Manage your plan** (always visible).
- Server endpoint/function to generate portal link for authenticated `uid`.
- Return URL + deep-link handling.
- Membership refresh after returning from portal.
- Error states (`no_customer`, network failure, expired link) with retry CTA.
- Analytics events (`manage_plan_tap`, `portal_opened`, `portal_returned`).

### 4.4 Custom integration (alternative)

If you outgrow the extension or need bespoke proration logic:

1. **Cloud Functions** expose HTTPS endpoints for **Stripe webhooks** (verify signature with webhook secret).
2. On `customer.subscription.updated`, `deleted`, `invoice.paid`, etc., **upsert** a document such as `users/{uid}` fields or `users/{uid}/billing/status` and optionally **set custom claims** via Admin SDK.
3. **Firestore security rules** allow reads only for `request.auth.uid` and **deny** client writes to billing fields.

Document secrets in **Secret Manager**; never put Stripe secrets in the client.

### 4.5 Data shape (illustrative—finalize in `data-model.md`)

Keep Stripe IDs and status on the user or a dedicated subcollection, for example:

- `stripeCustomerId`
- `subscriptionStatus` (`active`, `trialing`, `past_due`, `canceled`, …)
- `priceId` or `productId` (for entitlement mapping)
- `currentPeriodEnd` (for UI messaging)

Use **`Timestamp`** for period boundaries. **Clients read; only Functions write.**

---

## 5. References (stable links)

See **[`docs/references/README.md`](references/README.md)** for the Stripe + Firebase pointer list (extension, Stripe docs, webhook signing).

---

## 6. Revision log

| Date | Change |
|------|--------|
| 2026-04-15 | Initial doc: freemium UX patterns, entitlements, Stripe + Firebase options, Flutter store policy caveat. |
| 2026-04-15 | Added Settings “Manage your plan” flow using Stripe Customer Portal magic link + MVP checklist. |
