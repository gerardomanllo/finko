import type { BotLocale } from "./sessions";

/**
 * Short greetings / thanks with no transaction amount — nudge users toward /help
 * instead of the raw "include an amount" parser error.
 */
const SMALL_TALK_TOKENS = new Set([
  "hi",
  "hello",
  "hey",
  "yo",
  "sup",
  "thanks",
  "thx",
  "ty",
  "hola",
  "buenas",
  "saludos",
  "gracias",
  "ola",
]);

/** Lowercase, trimmed input (e.g. `text.trim().toLowerCase()`). */
export function looksLikeSmallTalk(norm: string): boolean {
  const stripped = norm.replace(/[!?.]+$/, "").trim();
  if (!stripped || stripped.length > 48) return false;
  if (/\d/.test(stripped)) return false;

  if (/^(hi|hello|hey)\s+there$/.test(stripped)) return true;
  if (/^good\s+(morning|afternoon|evening)$/.test(stripped)) return true;
  if (/^buenos\s+(días|dias|tardes|noches)$/.test(stripped)) return true;
  if (/^(thank\s+you|thanks|thx|gracias|muchas\s+gracias)$/.test(stripped)) return true;
  if (/^qu[eé]\s+tal$/.test(stripped)) return true;

  const words = stripped.split(/\s+/);
  if (words.length <= 2) {
    if (SMALL_TALK_TOKENS.has(stripped)) return true;
    if (words.length === 1 && SMALL_TALK_TOKENS.has(words[0])) return true;
  }

  return false;
}

/**
 * Language for the small-talk reply: match clear Spanish vs English greetings/thanks;
 * default **es** (product default), so neutral or mixed input does not follow Telegram's `en` client.
 */
export function localeForSmallTalkReply(norm: string): BotLocale {
  const stripped = norm.replace(/[!?.]+$/, "").trim().toLowerCase();
  if (!stripped) return "es";

  if (/[¿¡ñ]/.test(stripped)) return "es";

  if (/^buenos\s+(días|dias|tardes|noches)$/.test(stripped)) return "es";
  if (/^qu[eé]\s+tal$/.test(stripped)) return "es";
  if (/^(hola|buenas|saludos|gracias|muchas\s+gracias|ola)$/.test(stripped)) return "es";

  if (/^good\s+(morning|afternoon|evening)$/.test(stripped)) return "en";
  if (/^(hi|hello|hey)\s+there$/.test(stripped)) return "en";
  if (/^(thank\s+you|thanks|thx|ty)$/.test(stripped)) return "en";
  if (/^(hi|hello|hey)$/.test(stripped)) return "en";

  const words = stripped.split(/\s+/);
  if (words.length <= 2) {
    if (words.length === 1 && SMALL_TALK_TOKENS.has(words[0])) {
      if (
        words[0] === "hola" ||
        words[0] === "buenas" ||
        words[0] === "saludos" ||
        words[0] === "gracias" ||
        words[0] === "ola" ||
        words[0] === "yo" ||
        words[0] === "sup"
      ) {
        return "es";
      }
      if (words[0] === "hi" || words[0] === "hello" || words[0] === "hey" || words[0] === "thanks" || words[0] === "thx" || words[0] === "ty") {
        return "en";
      }
    }
    if (SMALL_TALK_TOKENS.has(stripped)) {
      return ["hola", "buenas", "saludos", "gracias", "ola", "yo", "sup"].includes(stripped) ? "es" : "en";
    }
  }

  return "es";
}
