# Telegram bot — automated testing (Functions)

Fixture JSON lives under **`functions/test/telegram/fixtures/`** (Telegram-shaped **`Update`** payloads, no secrets).

## Coverage

| Area | Tests |
|------|--------|
| **Classification gate** | `classifyTelegramFixtures.test.ts` loads each fixture and asserts `classifyTelegramUpdate` outcome (supported route vs graceful reject vs silent ignore). |
| **Emoji / unicode** | `classifyEmoji.test.ts` exercises **`isEmojiOrSymbolOnlyText`** (ZWJ sequences, skin tones, bidi marks). |
| **Callback parsing** | `telegramCallbackParse.test.ts` for **`parseTelegramCallbackData`** (valid codes vs tampered payloads). |
| **Webhook handler** | `handleTelegramUpdate.mocked.test.ts` uses **`createMockFirestoreForTelegram`** + mocked **`fetch`**: duplicate `update_id`, silent ignore, graceful reject DM, plain `/start`, unbound chat, bound `/help`, no double-send on retry. |

## Running

From **`functions/`**:

```bash
npm test
```

CI: **`flutter.yml`** runs **`npm ci && npm test`** in **`functions/`** on each PR/push.

## Adding rows

When **`classifyTelegramUpdate`** gains a new branch, add **`update_<case>.json`** plus a table row in **`classifyTelegramFixtures.test.ts`**. Prefer one outbound Telegram assertion per user-visible path in **`handleTelegramUpdate.mocked.test.ts`** when behavior is routing-specific.

## Revision log

| Date | Change |
|------|--------|
| 2026-05-01 | Initial matrix-linked fixture suite + mocked Firestore/fetch tests for `handleTelegramUpdate`. |
