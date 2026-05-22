/** Top-level collection: single-use deep-link tokens (Admin / Functions only). */
export const TELEGRAM_LINK_TOKENS = "telegramLinkTokens";

/** Doc id = Telegram chat id string → Firebase uid (Functions only). */
export const TELEGRAM_CHAT_BINDINGS = "telegramChatBindings";

/** Bot DM conversation draft state per chat (Functions only). */
export const TELEGRAM_BOT_SESSIONS = "telegramBotSessions";

/** In-app agent FSM per Firebase uid (Functions only). */
export const APP_AGENT_SESSIONS = "appAgentSessions";

/** Webhook idempotency — Telegram may retry the same `update_id`. */
export const TELEGRAM_PROCESSED_UPDATES = "telegramProcessedUpdates";

/** Subcollection under `users/{uid}` — bound chat (Functions + webhook only). */
export const TELEGRAM_LINK_SUBCOLLECTION = "_telegramLink";

export const TELEGRAM_LINK_STATE_DOC = "state";

export const LINK_TOKEN_PREFIX = "link_";

/** Deep-link token lifetime (Telegram users may switch apps slowly). */
export const LINK_TOKEN_TTL_MS = 24 * 60 * 60 * 1000;

/** Bot session TTL — refreshed each inbound update from bound chats. */
export const BOT_SESSION_TTL_MS = 30 * 60 * 1000;

/** Reject pasted Telegram payloads beyond this length (no LLM). */
export const TELEGRAM_MAX_TEXT_CHARS = 2000;

export const OTP_MIN_INTERVAL_MS = 60 * 1000;
