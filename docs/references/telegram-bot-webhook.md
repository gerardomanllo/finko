# Telegram bot (webhook + linking)

Finko uses a **Telegram Bot** to bind each Firebase user to a **`chat_id`** (magic link + **`/start`**) and to write **`integrations.telegram`**. After linking, the same webhook runs a **DM chatbot** (text/voice/photo, inline keyboards, expense/income/transfer/recurring flows) using **`classifyTelegramUpdate`** as the first gate, Firestore sessions/bindings, optional **Gemini** when **`GEMINI_API_KEY`** is set, and **200 OK** responses even when inbound updates are unsupported. There is **no Telegram OTP** for linking.

## Cloud Functions

| Export | Type | Role |
|--------|------|------|
| `telegramWebhook` | HTTPS (`onRequest`) | Verifies **`secret_token`** → idempotent **`update_id`** → **`classifyTelegramUpdate`** → **`handleTelegramUpdate`**: `/start link_<token>` bind transaction (**`_telegramLink`**, **`integrations.telegram`**, token consume), or bound-chat ledger/dialog (**`telegramChatBindings`**, **`telegramBotSessions`**). |
| `requestMessagingOtp` | Callable | **Telegram:** mints link token + returns **`tg://resolve?domain=…&start=link_<token>`** when needed; if already linked, returns **`messagingReady`**. **WhatsApp:** OTP challenge only. |
| `verifyMessagingOtp` | Callable | **WhatsApp:** verifies OTP and writes `integrations.whatsapp`. **Telegram:** no OTP — returns **`ok`** if `integrations.telegram` already exists, otherwise **`failed-precondition`**. |
| `disconnectMessagingIntegration` | Callable | Removes Telegram (or WhatsApp) integration, clears **`_telegramLink`** / OTP challenge, and for Telegram deletes **`telegramChatBindings`** + **`telegramBotSessions`** for the stored **`chatId`**. |

Deployed region (current): **`us-central1`**.

## Secrets and parameters (Google Cloud / Firebase)

Configure before deploy (per Firebase project: **dev** vs **prod**):

| Name | Kind | Purpose |
|------|------|---------|
| `TELEGRAM_BOT_TOKEN` | **Secret** (`defineSecret`) | Bot API token from [@BotFather](https://t.me/BotFather). |
| `TELEGRAM_WEBHOOK_SECRET` | **Secret** | Value passed to Telegram `setWebhook` as `secret_token`; the webhook rejects requests whose `X-Telegram-Bot-Api-Secret-Token` header does not match. |
| `TELEGRAM_BOT_USERNAME` | **String param** | Bot username **without** `@` (e.g. `FinkoDevBot`) for `https://t.me/<username>?start=...` deep links. If you store `@FinkoDevBot`, strip the `@` in config — a leading `@` breaks `t.me` links and looks like an “invalid / expired” deep link in Telegram. |
| `TELEGRAM_WEBHOOK_DEV_BYPASS` | **String param** (optional) | Set to `true` **only** for local emulator testing to skip secret header verification. **Never** in production. |
| `GEMINI_API_KEY` | **String param** (optional) | When non-empty, enables **Gemini** NLU / multimodal parsing for Telegram chat lines, receipt images, and voice; otherwise the bot relies on **heuristics** for text. |

Bind secrets to the functions that need them (CLI examples use current Firebase tooling):

```bash
# Create/update secrets (interactive; run per project after `firebase use <alias>`)
npx -y firebase-tools@latest functions:secrets:set TELEGRAM_BOT_TOKEN
npx -y firebase-tools@latest functions:secrets:set TELEGRAM_WEBHOOK_SECRET
```

Set **`TELEGRAM_BOT_USERNAME`**, optional **`TELEGRAM_WEBHOOK_DEV_BYPASS`**, and optional **`GEMINI_API_KEY`** in Firebase **environment params** for Functions (Console: Google Cloud → Cloud Functions → your function → **Edit** → **Runtime, build, connections and security variables**, or use `firebase functions:config` successors as documented for your CLI version).

## Register the webhook (after deploy)

Webhook URL shape:

`https://us-central1-<PROJECT_ID>.cloudfunctions.net/telegramWebhook`

Example `setWebhook` (replace placeholders; keep `secret_token` aligned with `TELEGRAM_WEBHOOK_SECRET`):

```bash
curl -sS "https://api.telegram.org/bot<BOT_TOKEN>/setWebhook" \
  -d "url=https://us-central1-<PROJECT_ID>.cloudfunctions.net/telegramWebhook" \
  -d "secret_token=<SAME_AS_TELEGRAM_WEBHOOK_SECRET>" \
  -d "allowed_updates=[\"message\",\"callback_query\",\"my_chat_member\"]"
```

Include **`callback_query`** so inline keyboard taps reach the webhook. **`my_chat_member`** is optional (ignored today but useful for future block/unblock hygiene).

Verify with **`getWebhookInfo`**. Use **dev** project URL for dev bot and **prod** for production bot.

## Runtime data (Firestore)

| Path | Role |
|------|------|
| `telegramChatBindings/{chatId}` | Resolve Telegram DM → Firebase **`uid`**. |
| `telegramBotSessions/{chatId}` | Wizard / draft (**merge** updates per inbound message). |
| `telegramProcessedUpdates/{updateId}` | Telegram **`update_id`** dedupe. |
| `users/{uid}.telegramBotPreferences` | Optional defaults edited from **Settings → Telegram → Bot defaults**. |

Client SDK **cannot** access the three **`telegram*`** collections (see **`firestore.rules`**).

## Manual QA checklist

1. **Link:** `/start link_<token>` → **`integrations.telegram`** + binding doc.
2. **Plain `/start`** → localized hint (no uncaught errors).
3. **Unbound** user sends text → single “link from app” DM.
4. **Expense** `12 coffee` → confirm keyboard → **`transactions`** row in Firestore.
5. **Sticker / video** → one friendly reject line.
6. **Retry same `update_id`** → no duplicate outbound messages.
7. **Linked user** sends **`hello`** → **`small_talk_hint`** (examples + `/help`), not only “include an amount”.
8. **Bad / expired link token** on **`/start link_…`** → localized **`link_token_*`** DM (not silent).

## Automated tests

Fixture-driven Jest suite + mocked **`fetch`**: [`telegram-bot-testing.md`](telegram-bot-testing.md).

## Logs Explorer

**`telegramWebhook`** emits structured **`logger.info` / `logger.warn`** lines (prefix `telegramWebhook:`) with JSON fields such as **`updateId`**, **`chatId`**, **`tokenPrefix`**, **`uid`** (on successful bind), and **`textPreview`** when the message is not a link token. In Logs Explorer, filter on the function name or e.g. `jsonPayload.message =~ "telegramWebhook"`.

## End-user flow (summary)

1. User enters `@username` or phone and taps **Next** (callable mints link token when needed).
2. If not yet linked to the bot, the app receives **`needsBotStart`** + **`deepLink`**. The callable returns **`tg://resolve?domain=<bot>&start=link_<token>`** ([bot links](https://core.telegram.org/api/links): `start` is the deep-link payload). The sheet tries **`tg://`** then **`https://t.me/<bot>?start=link_<token>`**.
3. User taps **Start** in Telegram → the bot receives **`/start link_<token>`** → **`telegramWebhook`** runs a **Firestore transaction** that writes **`users/{uid}/_telegramLink/state`**, marks the token used, sets **`integrations.telegram`**, and the bot sends a short “connected” DM.
4. The app detects **`chatId`** on **`_telegramLink/state`** (or profile already shows Telegram) → user taps **Done**; no OTP step.

## Troubleshooting (deep link / “expired”)

- **Plain `/start` in Telegram (no `link_…` token)** means the user did **not** open the **`start=link_<token>`** deep link (e.g. they searched the bot and tapped Start, or the OS dropped the query string). The app opens **`tg://resolve?domain=<bot>&start=link_<token>`** first, then **`https://t.me/…`**.
- **Token + link state + `integrations.telegram`** are written in one **Firestore transaction** so a failed profile write cannot “burn” a valid token.
- **Idempotent `/start`:** if Telegram retries the same `/start` for an already-used token but the **same `chat_id`**, the webhook succeeds again (no false “used” for the same user).
- **Link tokens** are **32-char lowercase hex** (Telegram `start` payload safe) and valid **24 hours** from creation.
- **`TELEGRAM_BOT_USERNAME`:** must **not** include `@`.

## Revision log

| Date | Change |
|------|--------|
| 2026-05-04 | **DM copy:** short greetings / thanks → **`small_talk_hint`** (examples + `/help`); failed **`/start link_…`** bind → **`link_token_expired`**, **`link_token_used_other`**, or **`link_token_invalid`** (no silent failure); unexpected handler errors → **`generic_error`** DM (details still in logs only). |
| 2026-05-01 | DM **chatbot** architecture: classification gate, **`allowed_updates`** incl. **`callback_query`**, **`GEMINI_API_KEY`**, Firestore runtime paths, QA checklist, pointer to [`telegram-bot-testing.md`](telegram-bot-testing.md). **`disconnectMessagingIntegration`** clears bindings/sessions. |
| 2026-04-21 | **No Telegram OTP:** **`integrations.telegram`** is written in the **webhook transaction** with **`_telegramLink/state`**; app flow is magic link + **Done** only. |
| 2026-04-21 | **`telegramWebhook`:** structured Cloud Logging for each update (parse / bind / `sendMessage`), without logging secrets or full tokens. |
| 2026-04-21 | Callable + client use **`tg://resolve?…&start=link_<token>`** (Telegram bot **`start`** payload) so the webhook still sees **`/start link_<token>`**; sheet mirrors **`https://t.me/…?start=…`**. |
| 2026-04-22 | Document `tg://resolve` + plain `/start` (no payload); client prefers `tg://` before `https://t.me`; webhook accepts `/start@Bot… link_…`. |
| 2026-04-22 | Deep-link fixes: transactional bind + hex token + 24h TTL + strip `@` from bot username; troubleshooting notes. |
| 2026-04-22 | Firestore: **`users/{uid}/_telegramLink`** is **client-readable** (same `uid`) so the app can listen for `chatId` after the user taps **Start** in Telegram. |
| 2026-04-21 | Initial doc: webhook URL, secrets/params, `setWebhook`, and function map aligned with repo implementation. |
