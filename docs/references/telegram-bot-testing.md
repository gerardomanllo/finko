# Telegram bot — automated testing (Functions)

Fixture JSON lives under **`functions/test/telegram/fixtures/`** (Telegram-shaped **`Update`** payloads, no secrets).

## Coverage

| Area | Tests |
|------|--------|
| **Classification gate** | `classifyTelegramFixtures.test.ts` loads each fixture and asserts `classifyTelegramUpdate` outcome (supported route vs graceful reject vs silent ignore). |
| **Emoji / unicode** | `classifyEmoji.test.ts` exercises **`isEmojiOrSymbolOnlyText`** (ZWJ sequences, skin tones, bidi marks). |
| **Callback parsing** | `telegramCallbackParse.test.ts` for **`parseTelegramCallbackData`** (valid codes vs tampered payloads). |
| **Webhook handler** | `handleTelegramUpdate.mocked.test.ts` uses **`createMockFirestoreForTelegram`** + mocked **`fetch`**: duplicate `update_id`, silent ignore, graceful reject DM, plain `/start`, unbound chat, bound `/help`, no double-send on retry. |
| **Inline keyboards / callbacks** | `handleTelegramCallback.mocked.test.ts` asserts Bot API contract for **`callback_query`**: **`answerCallbackQuery`** first (with toast copy on confirm/cancel), then **`editMessageText`** (posted expense only, no recurring prompt) or **`sendMessage`** (cancelled). Includes a picker regression test that verifies account buttons (`pa:*`) appear after category selection when account is unresolved. Uses **`createMockFirestoreForTelegram({ statefulBotSession: true, botSession: … })`** so session merges match production. Fixtures: `update_callback_query_confirm.json`, `update_callback_query_cancel.json`, `update_callback_query_confirm_wrong_step.json`. |

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
| 2026-05-08 | Added strict language-detection tests for text turns (`language_not_understood` fallback / detected-language reply), callback coverage for account-picker inline buttons, and assertion that standard confirm no longer prompts recurring. |
| 2026-05-07 | Stateful **`telegramBotSessions`** mock + **`handleTelegramCallback.mocked.test.ts`** for confirm/cancel/wrong-step **`callback_query`** flows. |
| 2026-05-01 | Initial matrix-linked fixture suite + mocked Firestore/fetch tests for `handleTelegramUpdate`. |
