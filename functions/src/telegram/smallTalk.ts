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
