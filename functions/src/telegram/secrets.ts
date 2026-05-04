import { defineSecret, defineString } from "firebase-functions/params";

export const telegramBotToken = defineSecret("TELEGRAM_BOT_TOKEN");
export const telegramWebhookSecret = defineSecret("TELEGRAM_WEBHOOK_SECRET");

/** Public bot handle without @ (e.g. `FinkoDevBot`) for `t.me/...` deep links. */
export const telegramBotUsername = defineString("TELEGRAM_BOT_USERNAME", { default: "" });

/** Set to `true` only for local emulator testing without webhook secret. */
export const telegramWebhookDevBypass = defineString("TELEGRAM_WEBHOOK_DEV_BYPASS", {
  default: "",
});

/** Optional Google AI Studio key for Gemini NLU / multimodal in Telegram bot. */
export const geminiApiKeyParam = defineString("GEMINI_API_KEY", { default: "" });
