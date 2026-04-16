# Settings

## Route

- `/settings`

## Purpose

- App preferences and optional **messaging channel** setup (not OAuth login).

## UI — stock settings layout

- Standard **settings** page structure (grouped sections / list tiles).

### Appearance

- **Dark / light theme** selector (toggle or segmented control).

### Membership

- Add a **Manage your plan** CTA that opens the user-specific Stripe Customer Portal link.
- Portal link must be generated **server-side** for authenticated `uid` (single-use URL), then opened by the app.
- On return from portal, refresh membership state and entitlements.

### Messaging integrations (optional)

- Separate **CTAs** so the user can **connect or configure** (implement as “Set up”, “Connect”, or “Manage” per design):
  - **WhatsApp** — user-created link / flow to **send transactions** or **query their data** through WhatsApp (backend handles the channel; the app only exposes setup UX).
  - **Telegram** — same idea for Telegram (or connected bot/channel).
- User may connect **one, both, or neither** — do not require both.
- Show **status** per channel (“Not connected”, “Connected”, “Pending”) — stub strings until backend exists.

## Navigation

- **In**: Drawer → **Settings**.

## Reuse

- Shared settings row / section widgets.

## Data (frontend phase)

- `ThemeMode` persistence local-only until Firebase/backend.
- Channel connection state: mock toggles or flags.

## Acceptance

- [ ] Theme switch applies globally (via `ThemeMode` / provider).
- [ ] **Manage your plan** CTA exists and opens a server-generated Stripe Customer Portal link.
- [ ] **At least two** distinct CTAs: WhatsApp and Telegram (handlers stubbed).
- [ ] Copy does **not** imply WhatsApp/Telegram are sign-in methods.
