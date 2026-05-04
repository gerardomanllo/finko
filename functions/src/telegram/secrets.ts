import { defineSecret, defineString } from "firebase-functions/params";

export const telegramBotToken = defineSecret("TELEGRAM_BOT_TOKEN");
export const telegramWebhookSecret = defineSecret("TELEGRAM_WEBHOOK_SECRET");

/** Public bot handle without @ (e.g. `FinkoDevBot`) for `t.me/...` deep links. */
export const telegramBotUsername = defineString("TELEGRAM_BOT_USERNAME", { default: "" });

/** Set to `true` only for local emulator testing without webhook secret. */
export const telegramWebhookDevBypass = defineString("TELEGRAM_WEBHOOK_DEV_BYPASS", {
  default: "",
});

/** Google AI / Gemini API key — Secret Manager id **`GEMINI_API_KEY`**. If deploy fails with “secret overlaps non-secret”, remove legacy **plain** `GEMINI_API_KEY` from Cloud Run env first (see `docs/references/telegram-bot-webhook.md`). */
export const geminiApiKey = defineSecret("GEMINI_API_KEY");
