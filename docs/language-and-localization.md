# Language & localization

This document defines **which languages Finko supports**, the **default**, and how that ties to **UI strings**, **formatting**, and the **`locale`** field on the user profile ([`data-model.md`](data-model.md) §3).

---

## Supported languages

| Language | BCP 47 (recommended) | Notes |
|----------|----------------------|--------|
| **Spanish** | `es` or region-qualified (e.g. `es-MX`) | **Default** app UI language. Use a region tag when copy or formats should match a specific market (e.g. Mexico). |
| **English** | `en` or `en-US` | Full parity with Spanish for every user-visible string. |

**Minimum bar:** **Spanish** and **English** must both be complete for **the entire app** (shell, onboarding, every screen, dialogs, empty states, errors, and validation messages). No feature ships with strings in only one language.

---

## Default language

- **Default UI language is Spanish.** On first launch, the app uses Spanish for all copy unless the user changes it (e.g. in Settings).
- **Persistence:** The chosen locale is stored as the profile field **`locale`** (BCP 47 string) and must stay in sync with the active `Locale` / `Localizations` in the Flutter app.
- **Device locale:** If you add automatic detection later, document it here; until then, **do not** assume the device language replaces the product default without an explicit UX decision.

---

## Implementation (Flutter)

- **Strings:** Use Flutter **gen-l10n** (ARB files) or an equivalent supported workflow. **Canonical enum values** in Firestore (e.g. account `type`) stay **English/stable** in the database; **labels** come from ARB maps ([`data-model.md`](data-model.md) §5–6).
- **Formatting:** Dates, numbers, and currency symbols follow the active locale and `Intl` / `flutter_localizations`; business rules for **main currency** and **day-only dates** remain as in [`data-model.md`](data-model.md).
- **Scope:** Add **both** `app_es.arb` and `app_en.arb` (or your chosen naming) for every new user-facing key; avoid hardcoded user-visible strings in `lib/` for production UI.

### First-time gen-l10n bootstrap

When turning on localization in the repo for the first time:

1. Add **`flutter_localizations`** (SDK) and **`intl`** to `pubspec.yaml`; set **`generate: true`** under `flutter:` if using Flutter’s synthetic l10n package, or follow the [official gen-l10n](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization) layout for your Flutter version.
2. Add **`l10n.yaml`** at the project root (or the path your team chooses) and place ARBs under e.g. **`lib/l10n/`**, with **`app_es.arb`** and **`app_en.arb`** as the minimum pair.
3. Run **`flutter gen-l10n`** (or let the toolchain generate on build) so CI’s **`flutter pub get`** + analyze see the same outputs developers use.
4. Wire **`MaterialApp.router`** (or the root app widget) with **`localizationsDelegates`**, **`supportedLocales`**, and a **Riverpod**- or settings-driven locale override so `users/{uid}.locale` stays in sync with the active `Locale`.

---

## Settings & onboarding

- **Settings** should expose a **language** control (Spanish / English) that updates the in-memory locale and persists **`users/{uid}.locale`**.
- **Onboarding** includes language selection in step 1 (see [`onboarding.md`](onboarding.md)); default app language remains **Spanish** per above if unchanged.

Align screen behavior with [`settings.md`](settings.md) and [`onboarding.md`](onboarding.md) when those flows define the control.

---

## Testing & QA

- Smoke-test **both** locales on navigation-critical paths (login → dashboard → primary tabs).
- Widget or golden tests that depend on text should set an explicit **`locale`** in the test harness so they do not flake on developer machine language.

---

## Related docs

- [`onboarding.md`](onboarding.md) — step 1 language picker + persistence to `locale`.
- [`data-model.md`](data-model.md) — `locale` on `users/{uid}`; canonical enums vs localized labels.
- [`data-contract.md`](data-contract.md) — profile fields surfaced to UI.
- [`docs/references/README.md`](references/README.md) — optional links to Flutter i18n docs when added.
