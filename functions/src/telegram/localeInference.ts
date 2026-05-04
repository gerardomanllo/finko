import type { BotLocale } from "./sessions";
import type { TelegramMessage } from "./types";

/**
 * Returns es/en when message text has strong language signals; otherwise null
 * (caller falls back to Telegram language_code, then product default).
 */
export function inferBotLocaleFromUserText(text: string): BotLocale | null {
  const s = text.normalize("NFC").trim();
  if (s.length === 0) return null;

  if (/[¿¡ñÁÉÍÓÚÜáéíóúü]/.test(s)) return "es";

  if (
    /\b(pesos?|gast[eé]|compr[eé]|pagu[eé]|supermercado|mercado|caf[eé]|nómina|dinero|tarjeta|efectivo)\b/i.test(
      s
    )
  ) {
    return "es";
  }

  if (
    /\b(spent|bought|paid|purchase|dollars?|bucks|usd|gbp|euros?|quid|cash|card)\b/i.test(s)
  ) {
    return "en";
  }

  return null;
}

/**
 * Reply language precedence:
 * 1. telegramBotPreferences.localeOverride (es | en)
 * 2. Strong signal from user-generated text (caption, DM text, etc.)
 * 3. Telegram `language_code`
 * 4. Default es
 */
export function pickBotLocale(params: {
  localeOverride?: string | null;
  userText?: string | null;
  message?: TelegramMessage;
}): BotLocale {
  const o = params.localeOverride?.trim().toLowerCase();
  if (o === "es" || o === "en") return o;

  const raw = params.userText?.trim();
  if (raw && raw.length > 0) {
    const fromText = inferBotLocaleFromUserText(raw);
    if (fromText) return fromText;
  }

  const code = params.message?.from?.language_code?.trim().toLowerCase() ?? "";
  if (code.startsWith("es")) return "es";
  if (code.startsWith("en")) return "en";
  return "es";
}
