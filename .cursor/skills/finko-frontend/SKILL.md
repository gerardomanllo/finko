---
name: finko-frontend
description: Implements Finko personal-finance Flutter UI from project docs with DRY widgets. Use when building or changing screens, navigation shell, login, charts, lists, or when the user mentions Finko, docs/screens, or frontend-only stubs.
---

# Finko frontend (Flutter)

## Before coding

1. Open `docs/README.md` → find the screen file for the route.
2. Read that screen doc end-to-end (navigation, sections, acceptance checklist).
3. Read `docs/components-inventory.md` and reuse or extend listed building blocks.

## While coding

- Stub **data** in repositories/providers with mocks/fakes; **do not** wire Firestore or other backend reads/writes unless the task explicitly covers backend. **`firebase_core`** may still run at app bootstrap (dev/prod flavors)—that is **environment wiring**, not product data.
- Implement **navigation** exactly as in `docs/shell-navigation.md` (bottom tabs + drawer from **More**). Primary tab route is **`/dashboard`** (not `/home`).
- **Login** uses email/password + **Google** + **Apple** only; WhatsApp/Telegram are **Settings** integrations, not auth providers.
- When adding a reusable visual, add a **one-line** entry to `docs/components-inventory.md` with the widget name and consumers.

## DRY checklist

- Second copy of the same card header, list row, or accordion? → Extract widget.
- Same metric layout on dashboard cards? → One `MetricCarouselCard` (or equivalent) with slots.

## After coding

- Verify the screen doc **Acceptance** bullets where applicable.
- If product rules changed, update the **screen `docs/*.md`** in the same PR/commit as the code.
