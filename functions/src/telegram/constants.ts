/** Top-level collection: single-use deep-link tokens (Admin / Functions only). */
export const TELEGRAM_LINK_TOKENS = "telegramLinkTokens";

/** Subcollection under `users/{uid}` — bound chat (Functions + webhook only). */
export const TELEGRAM_LINK_SUBCOLLECTION = "_telegramLink";

export const TELEGRAM_LINK_STATE_DOC = "state";

export const LINK_TOKEN_PREFIX = "link_";

/** Deep-link token lifetime (Telegram users may switch apps slowly). */
export const LINK_TOKEN_TTL_MS = 24 * 60 * 60 * 1000;

export const OTP_MIN_INTERVAL_MS = 60 * 1000;
