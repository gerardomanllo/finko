import { LINK_TOKEN_PREFIX } from "./constants";

/**
 * Returns `telegramLinkTokens/{id}` document id from `/start link_<id>`.
 * Accepts `/start@BotUsername link_<id>` (Telegram command form in some clients).
 */
export function telegramStartLinkTokenFromMessageText(text: string): string | null {
  const t = text.trim();
  const m = /^\/start(?:@[A-Za-z0-9_]+)?(?:\s+(.+))?$/s.exec(t);
  if (!m) {
    return null;
  }
  const raw = (m[1] ?? "").trim();
  if (!raw) {
    return null;
  }
  const firstToken = (raw.split(/\s+/)[0] ?? "").trim();
  if (!firstToken.startsWith(LINK_TOKEN_PREFIX)) {
    return null;
  }
  let id = firstToken.slice(LINK_TOKEN_PREFIX.length).trim();
  if (id.length === 0) {
    return null;
  }
  try {
    if (id.includes("%")) {
      id = decodeURIComponent(id);
    }
  } catch {
    return null;
  }
  return id.length > 0 ? id : null;
}
