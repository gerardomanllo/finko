# Telegram bot (webhook + linking)

Finko uses a **Telegram Bot** to bind each Firebase user to a **`chat_id`** (magic link + **`/start`**) and to write **`integrations.telegram`**. After linking, the same webhook runs a **DM chatbot** (text/voice/photo, inline keyboards, expense/income/transfer/recurring flows) using **`classifyTelegramUpdate`** as the first gate, Firestore sessions/bindings, optional **Genkit (JS) + Google AI** when Secret Manager **`GEMINI_API_KEY`** is set (via **`defineSecret`**), and **200 OK** responses even when inbound updates are unsupported. There is **no Telegram OTP** for linking.

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
| `GEMINI_API_KEY` | **Secret** (`defineSecret`) | When non-empty at runtime, enables **Genkit**-driven **Gemini** conversational NLU (Spanish/English) / multimodal parsing for Telegram lines, receipt images, and voice (`googleai/gemini-2.5-flash`); otherwise the bot uses **amount-first heuristics** for simple text (e.g. `50 coffee`). **Conversational** phrases (e.g. “gasté 100 pesos…”) need this in production. Use **Secret Manager** only — **not** as a plain Cloud Run / Console env var (see **Troubleshooting (deploy)** if a legacy plain row blocks deploy). |

Bind secrets to the functions that need them (CLI examples use current Firebase tooling):

```bash
# Create/update secrets (interactive; run per project after `firebase use <alias>`)
npx -y firebase-tools@latest functions:secrets:set TELEGRAM_BOT_TOKEN
npx -y firebase-tools@latest functions:secrets:set TELEGRAM_WEBHOOK_SECRET
npx -y firebase-tools@latest functions:secrets:set GEMINI_API_KEY
```

Set **`TELEGRAM_BOT_USERNAME`** and optional **`TELEGRAM_WEBHOOK_DEV_BYPASS`** in Firebase **environment params** for Functions (Console: Google Cloud → Cloud Functions → your function → **Edit** → **Runtime, build, connections and security variables**, or use `firebase functions:config` successors as documented for your CLI version). **`GEMINI_API_KEY`** must be **Secret Manager + `defineSecret` only** — do **not** set it as a **plain** environment variable on **`telegramWebhook`** (that clashes with the secret binding and breaks deploy; see **Troubleshooting (deploy)**).

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

## Genkit AI layer (Functions)

When **`GEMINI_API_KEY`** is set, model calls run through **Genkit** (`genkit`, `@genkit-ai/google-genai`) under `functions/src/telegram/genkit/`: structured outputs (Zod) for **dialog** (`analyzeFirstMessageWithGemini` / `continueDialogWithGemini` via `dialogGenkit.ts`) and **NLU** (text line, receipt image, voice via `nluGenkit.ts`). The plugin is initialized with **`apiKey: false`** so each `generate` passes **`config.apiKey`** from the same secret the webhook injects (no second secret).

**Read-only Firestore tools** (optional on each turn, `uid` injected by **`handleTelegramUpdate`**, never from the model): **`list_accounts`**, **`list_categories`**, **`recent_transactions`** (`ledgerTools.ts`). Server-side **`validateTransactionSnapshot`** and confirm/post flows stay in plain TypeScript (`geminiOrchestrator.ts`, `handleUpdate.ts`).

When a first-turn Gemini **`transaction`** snapshot fails **`validateTransactionSnapshot`** but is already a **standard** expense/income with valid **direction**, a **positive** amount, and a **non-empty memo**—while **category** and/or **account** are missing or invalid after **`validateIds`**—**`handleTelegramUpdate`** merges that snapshot into the session draft and calls **`finalizeSpendCategoryResolution`**, which shows **inline pickers** (**`pc:`** / **`pa:`**) the same way as amount-first heuristics. Only genuinely incomplete or ambiguous parses (e.g. missing amount/memo, partial transfers, non-standard shape) fall through to **`gemini_collect`** + the model **`assistantMessage`**.

Transport (**`telegramWebhook`**, **`classifyTelegramUpdate`**, sessions, Telegram Bot API, ledger writes) is unchanged except for wiring and logging prefixes (**`telegramGenkit:`** on Genkit failures).

## Runtime data (Firestore)

| Path | Role |
|------|------|
| `telegramChatBindings/{chatId}` | Resolve Telegram DM → Firebase **`uid`**. |
| `telegramBotSessions/{chatId}` | Wizard / draft (**merge** updates per inbound message). |
| `telegramProcessedUpdates/{updateId}` | Telegram **`update_id`** dedupe. |
| `users/{uid}.telegramBotPreferences` | Optional defaults edited from **Settings → Telegram → Bot defaults** (includes optional **`localeOverride`**: `es` \| `en`). |

Client SDK **cannot** access the three **`telegram*`** collections (see **`firestore.rules`**).

## Reply language (bot copy)

For **text** turns, the bot runs a strict Gemini language-detection pass and accepts only **`es`** or **`en`**:

1. If Gemini detects `es` or `en`, that locale is used for the whole turn and written to **`telegramBotSessions.locale`**.
2. If detection is not `es/en` (or Gemini key is unavailable), the bot replies with a localized **`language_not_understood`** message and stops processing the turn.

For **photo/voice** fallback and non-text contexts, locale still uses existing resolver heuristics (preference/message signals/Telegram metadata).

## Manual QA checklist

1. **Link:** `/start link_<token>` → **`integrations.telegram`** + binding doc.
2. **Plain `/start`** → localized hint (no uncaught errors).
3. **Unbound** user sends text → single “link from app” DM.
4. **Expense** `12 coffee` → confirm keyboard → **`transactions`** row in Firestore.
5. **Confirm** summary shows **direction, currency (ISO), numeric amount, name/memo, account, category**; posting happens **only** after **✓** (no auto-post from NLU alone).
6. **Spanish sentence** with Telegram UI in English (e.g. “gasté 100 pesos…”) → prompts in **Spanish** when **`localeOverride`** is unset and the text signals Spanish.
7. **Missing amount** after conversational parse → bot asks for amount; user sends `120` → flow continues to category/account/confirm as needed.
8. **`GEMINI_API_KEY` unset** (secret empty / missing) + text input → localized **`language_not_understood`** (strict text language detection requires Gemini).
9. **Sticker / video** → one friendly reject line.
10. **Retry same `update_id`** → no duplicate outbound messages.
11. **Linked user** sends **`hello`** with Gemini key set → reply in the detected language (ES/EN). If not ES/EN, return **`language_not_understood`**.
12. **Bad / expired link token** on **`/start link_…`** → localized **`link_token_*`** DM (not silent).

## Automated tests

Fixture-driven Jest suite + mocked **`fetch`**: [`telegram-bot-testing.md`](telegram-bot-testing.md).

## Logs Explorer

**`telegramWebhook`** emits structured **`logger.info` / `logger.warn`** lines (prefix `telegramWebhook:`) with JSON fields such as **`updateId`**, **`chatId`**, **`tokenPrefix`**, **`uid`** (on successful bind), and **`textPreview`** when the message is not a link token. In Logs Explorer, filter on the function name or e.g. `jsonPayload.message =~ "telegramWebhook"`.

## End-user flow (summary)

1. User enters `@username` or phone and taps **Next** (callable mints link token when needed).
2. If not yet linked to the bot, the app receives **`needsBotStart`** + **`deepLink`**. The callable returns **`tg://resolve?domain=<bot>&start=link_<token>`** ([bot links](https://core.telegram.org/api/links): `start` is the deep-link payload). The sheet tries **`tg://`** then **`https://t.me/<bot>?start=link_<token>`**.
3. User taps **Start** in Telegram → the bot receives **`/start link_<token>`** → **`telegramWebhook`** runs a **Firestore transaction** that writes **`users/{uid}/_telegramLink/state`**, marks the token used, sets **`integrations.telegram`**, and the bot sends a short “connected” DM.
4. The app detects **`chatId`** on **`_telegramLink/state`** (or profile already shows Telegram) → user taps **Done**; no OTP step.

## Troubleshooting (runtime: HTTP 200 but user sees “Something went wrong…”)

- **`telegramWebhook` always responds `200`** to Telegram once the handler finishes (see `telegramWebhook.ts`). Telegram treats non-2xx as delivery failures and retries; we acknowledge receipt even when we send a **generic_error** DM or log an internal failure.
- That English line is the **`generic_error`** string from `functions/src/telegram/i18n.ts`. It is sent when **`handleTelegramUpdate`** hits its **`catch`** (any uncaught exception after classification) **or** when both model turns return **`null`** (API/JSON/model errors — see **`telegramGenkit:`** logs: `analyzeFirstMessage failed` / `continueDialog failed`, and **`telegramWebhook: gemini_turn_null`** with a **`reason`** field).
- **Fix:** In Cloud Logging, filter for `handleTelegramUpdate failed` (includes **`stack`**) or `gemini_turn_null` / `telegramGenkit`. Typical causes: invalid/expired **`GEMINI_API_KEY`**, model not found (use a current **`googleai/gemini-2.5-*`** id in code), quota, or schema/validation errors from the provider.

## Troubleshooting (deploy)

- **`Secret environment variable overlaps non secret environment variable: GEMINI_API_KEY`:** Cloud Run cannot use the **same name** for both a **plain** environment variable and a **secret**. An older **`telegramWebhook`** revision often still has **`GEMINI_API_KEY`** under **Environment variables** (from a prior **`defineString`** / Console param), while the current code mounts **`GEMINI_API_KEY`** from **Secret Manager**. **Fix:** remove the **non-secret** **`GEMINI_API_KEY`** row, then deploy again (the secret binding from Firebase stays).
  - **Google Cloud Console:** **Cloud Run** → service **`telegramwebhook`** → **Edit & deploy new revision** → **Variables & secrets** → under **Environment variables**, **delete** **`GEMINI_API_KEY`** if it is a **literal value** (not “reference a secret”).
  - **CLI:** `gcloud run services update telegramwebhook --project=<PROJECT_ID> --region=us-central1 --remove-env-vars=GEMINI_API_KEY` (removes **literal** env vars only).
  - Inspect: `gcloud run services describe telegramwebhook --region=us-central1 --format='yaml(spec.template.spec.containers[0].env)'`.

## Troubleshooting (deep link / “expired”)

- **Plain `/start` in Telegram (no `link_…` token)** means the user did **not** open the **`start=link_<token>`** deep link (e.g. they searched the bot and tapped Start, or the OS dropped the query string). The app opens **`tg://resolve?domain=<bot>&start=link_<token>`** first, then **`https://t.me/…`**.
- **Token + link state + `integrations.telegram`** are written in one **Firestore transaction** so a failed profile write cannot “burn” a valid token.
- **Idempotent `/start`:** if Telegram retries the same `/start` for an already-used token but the **same `chat_id`**, the webhook succeeds again (no false “used” for the same user).
- **Link tokens** are **32-char lowercase hex** (Telegram `start` payload safe) and valid **24 hours** from creation.
- **`TELEGRAM_BOT_USERNAME`:** must **not** include `@`.

## Revision log

| Date | Change |
|------|--------|
| 2026-05-08 | **Strict text-language flow + no auto-recurring prompt:** Every text turn runs Gemini language detection (`es`/`en` only) and replies in the detected language; otherwise returns **`language_not_understood`**. Standard transaction confirm now posts immediately without follow-up recurring buttons. Picker flow adds defensive “no categories/accounts” messages instead of silent paths. **Gemini picker precedence:** Incomplete-but-standard snapshots (amount + memo + direction valid; category/account unset or unknown ids) route to **`finalizeSpendCategoryResolution`** and **`pc:`/`pa:`** keyboards instead of **`gemini_collect`** prose. |
| 2026-05-07 | **Callback UX + CI:** Confirm/cancel inline buttons call **`answerCallbackQuery`** with short localized text (**saved** / **discarded**) so clients show the standard callback notification. Jest (**`handleTelegramCallback.mocked.test.ts`**) locks in **answer → edit/send** order; keep **`setWebhook`** **`allowed_updates`** including **`callback_query`** (see **Register the webhook**). |
| 2026-05-04 | **Genkit prompts — reply language:** Dialog and NLU (text, receipt, voice, caption) prepend **`replyLanguageInstructions(locale)`** so **`assistantMessage`** / **`quickReply`** / NLU **memo** are in **English** or **Spanish** per the **bot UI locale** (session + resolver), not the raw DM language. **`handleTelegramUpdate`** passes **`locale`** / **`loc`** into **`parse*WithOptionalGemini`**. |
| 2026-05-04 | **Pickers + amounts:** Account/category prompts use inline keyboards with **`_pickAccountOrder`** / **`_pickCategoryOrder`** (and transfer **`_transferFromOrder`** / **`_transferToOrder`**) on the session draft so **`pa:`** / **`pc:`** / **`tf:`** / **`tt:`** indices resolve to stable ids; **`handleCallback`** rejects mismatched **`session.step`** for those actions and confirm/recurring buttons. User-visible amounts use **`formatLedgerAmountMinor`** (`CCY $x,xxx.xx`, e.g. **`MXN $50.00`**) on confirm and posted messages. |
| 2026-05-04 | **Genkit for Telegram AI:** Replaced direct **`@google/generative-ai`** usage with **Genkit** (`functions/src/telegram/genkit/`): model **`googleai/gemini-2.5-flash`**, Zod structured outputs, optional read-only Firestore tools (**`list_accounts`**, **`list_categories`**, **`recent_transactions`**) with **`uid`** from the handler. Snapshot parsing lives in **`telegramGeminiSnapshot.ts`**; API failures log **`telegramGenkit:`** prefixes. |
| 2026-05-04 | **Gemini model id (pre-Genkit):** Flash used **`gemini-2.0-flash`** (replacing **`gemini-1.5-flash`**). Superseded by **Genkit** + **`googleai/gemini-2.5-flash`** (see **Genkit for Telegram AI** row). |
| 2026-05-04 | **Observability:** `handleTelegramUpdate` error log includes **`outcome`** and **`stack`**; Gemini-null paths log **`telegramWebhook: gemini_turn_null`** with **`reason`**. |
| 2026-05-04 | **Gemini DM text (when `GEMINI_API_KEY` is set):** **`analyzeFirstMessageWithGemini`** for intent (**greeting** / **question** / **transaction**) + first extraction; on null/error, **`continueDialogWithGemini`** from empty draft — **no** **`parseTransactionLineWithOptionalGemini`** on text. **`gemini_collect`** and mid-flow continuations use **`continueDialogWithGemini`** with **`dialogIntent`** so topic switches clear the session without local classifiers. **`await_amount` / `await_memo`** and keyboard **`transfer_amount`** use continuation from session-draft snapshots when the key is set. Validate → **confirm** → **`postStandardTx`** / **`postTransferTx`**. Without the secret: heuristics + legacy parse only. |
| 2026-05-04 | **Callbacks:** `handleCallback` always **`answerCallbackQuery`** on errors (`try/catch`); coerce **`callback_query.id`** to string (JSON may use number); move **`loadMainCurrency`** after cancel; fallback **`telegramEditMessageTextOrSend`** when edit fails; **`advanceAfterCategory`** accepts picked row from **`pick_cat`** so stale `draft._categories` cannot block flow; default answer for unhandled `data`. |
| 2026-05-04 | **Small talk:** friendlier **`small_talk_hint`** (intro as Finko + assistant); reply language via **`localeForSmallTalkReply`** — Spanish for clear ES / default & ambiguous (`yo`/`sup`), English only for clear EN greetings/thanks (not Telegram client lang alone). |
| 2026-05-04 | **Sessions:** `upsertTelegramBotSession` omits **`undefined`** inside **`draft`** before Firestore writes (e.g. Gemini/heuristic parse without **`categoryId`** yet). |
| 2026-05-04 | **Deploy:** **`GEMINI_API_KEY`** stays Secret Manager + **`defineSecret`**; remove legacy **plain** **`GEMINI_API_KEY`** on Cloud Run when deploy reports secret/non-secret overlap. |
| 2026-05-04 | **Bilingual replies + NLU:** infer **`es`/`en`** from message text (with preference → text → Telegram code → default **`es`**); **Gemini** prompt includes **accounts + categories** and supports **nullable** amount/memo; session steps **`await_amount`** / **`await_memo`**; **confirm** shows explicit **currency** + **name** line. **`GEMINI_API_KEY`** (**`defineSecret`**), bound on **`telegramWebhook`**. |
| 2026-05-04 | **DM copy:** short greetings / thanks → **`small_talk_hint`** (examples + `/help`); failed **`/start link_…`** bind → **`link_token_expired`**, **`link_token_used_other`**, or **`link_token_invalid`** (no silent failure); unexpected handler errors → **`generic_error`** DM (details still in logs only). |
| 2026-05-01 | DM **chatbot** architecture: classification gate, **`allowed_updates`** incl. **`callback_query`**, **`GEMINI_API_KEY`**, Firestore runtime paths, QA checklist, pointer to [`telegram-bot-testing.md`](telegram-bot-testing.md). **`disconnectMessagingIntegration`** clears bindings/sessions. |
| 2026-04-21 | **No Telegram OTP:** **`integrations.telegram`** is written in the **webhook transaction** with **`_telegramLink/state`**; app flow is magic link + **Done** only. |
| 2026-04-21 | **`telegramWebhook`:** structured Cloud Logging for each update (parse / bind / `sendMessage`), without logging secrets or full tokens. |
| 2026-04-21 | Callable + client use **`tg://resolve?…&start=link_<token>`** (Telegram bot **`start`** payload) so the webhook still sees **`/start link_<token>`**; sheet mirrors **`https://t.me/…?start=…`**. |
| 2026-04-22 | Document `tg://resolve` + plain `/start` (no payload); client prefers `tg://` before `https://t.me`; webhook accepts `/start@Bot… link_…`. |
| 2026-04-22 | Deep-link fixes: transactional bind + hex token + 24h TTL + strip `@` from bot username; troubleshooting notes. |
| 2026-04-22 | Firestore: **`users/{uid}/_telegramLink`** is **client-readable** (same `uid`) so the app can listen for `chatId` after the user taps **Start** in Telegram. |
| 2026-04-21 | Initial doc: webhook URL, secrets/params, `setWebhook`, and function map aligned with repo implementation. |
