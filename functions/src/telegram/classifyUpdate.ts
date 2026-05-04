import { LINK_TOKEN_PREFIX } from "./constants";
import { telegramStartLinkTokenFromMessageText } from "./parseTelegramStart";
import type { TelegramCallbackQuery, TelegramMessage, TelegramUpdate } from "./types";

export type RejectReason =
  | "unsupported_media"
  | "message_too_long"
  | "emoji_only"
  | "empty_text";

export type ClassifyOutcome =
  | {
      outcome: "link_token";
      chatId: number;
      token: string;
      languageCode?: string;
      message?: TelegramMessage;
    }
  | {
      outcome: "plain_start";
      chatId: number;
      languageCode?: string;
      message?: TelegramMessage;
    }
  | {
      outcome: "callback_query";
      chatId: number;
      cq: TelegramCallbackQuery;
    }
  | {
      outcome: "dialog_text";
      chatId: number;
      messageId: number;
      text: string;
      languageCode?: string;
      message: TelegramMessage;
    }
  | { outcome: "photo"; chatId: number; message: TelegramMessage }
  | { outcome: "voice"; chatId: number; message: TelegramMessage }
  | {
      outcome: "graceful_reject";
      reason: RejectReason;
      chatId?: number;
      languageCode?: string;
    }
  | { outcome: "silent_ignore"; debug: string };

const MAX_TEXT = 2000;

function chatIdFromMessage(m?: TelegramMessage): number | undefined {
  const id = m?.chat?.id;
  return typeof id === "number" ? id : undefined;
}

/** True when visible content is only emoji / punctuation (no letters or digits). */
export function isEmojiOrSymbolOnlyText(text: string): boolean {
  const t = text.normalize("NFC").trim();
  if (t.length === 0) return false;
  let rest = t.replace(/\p{Extended_Pictographic}/gu, "");
  rest = rest.replace(/[\u{1F3FB}-\u{1F3FF}]/gu, "");
  rest = rest.replace(/[\s\p{P}\uFE0F\u200D\u200E\u200F\u061C]/gu, "").trim();
  return rest.length === 0;
}

function hasUnsupportedAttachment(msg: TelegramMessage): boolean {
  return Boolean(
    msg.sticker ||
      msg.video ||
      msg.video_note ||
      msg.animation ||
      msg.audio ||
      msg.document ||
      msg.location ||
      msg.venue ||
      msg.contact ||
      msg.poll ||
      msg.dice ||
      msg.game ||
      (msg.new_chat_members && msg.new_chat_members.length)
  );
}

/** Exported for tests — classify a Telegram `Update` before Firestore / NLU. */
export function classifyTelegramUpdate(update: TelegramUpdate): ClassifyOutcome {
  const uKeys =
    update && typeof update === "object" ? Object.keys(update as object).filter((k) => k !== "update_id") : [];

  if (update.inline_query !== undefined) {
    return { outcome: "silent_ignore", debug: "inline_query" };
  }
  if (update.channel_post !== undefined || update.edited_channel_post !== undefined) {
    return { outcome: "silent_ignore", debug: "channel_post" };
  }
  if (update.my_chat_member !== undefined) {
    return { outcome: "silent_ignore", debug: "my_chat_member" };
  }

  if (update.callback_query) {
    const cq = update.callback_query;
    const chatIdCb = chatIdFromMessage(cq.message);
    if (chatIdCb === undefined) {
      return { outcome: "silent_ignore", debug: "callback_query_no_chat" };
    }
    return { outcome: "callback_query", chatId: chatIdCb, cq };
  }

  if (update.edited_message) {
    return { outcome: "silent_ignore", debug: "edited_message" };
  }

  const msg = update.message;
  if (!msg) {
    return { outcome: "silent_ignore", debug: `no_message:${uKeys.join(",")}` };
  }

  const chatId = chatIdFromMessage(msg);
  if (chatId === undefined) {
    return { outcome: "silent_ignore", debug: "no_chat_id" };
  }

  const lang = msg.from?.language_code;

  const text = typeof msg.text === "string" ? msg.text : "";
  const caption = typeof msg.caption === "string" ? msg.caption : "";

  // Deep link always wins on text commands.
  const linkToken = telegramStartLinkTokenFromMessageText(text);
  if (linkToken) {
    return {
      outcome: "link_token",
      chatId,
      token: linkToken,
      languageCode: lang,
      message: msg,
    };
  }

  const trimmedStart = text.trim();
  if (/^\/start(?:@[A-Za-z0-9_]+)?(?:\s|$)/is.test(trimmedStart)) {
    const rest = trimmedStart.replace(/^\/start(?:@[A-Za-z0-9_]+)?\s*/is, "").trim();
    if (rest.length === 0 || !rest.startsWith(LINK_TOKEN_PREFIX)) {
      return { outcome: "plain_start", chatId, languageCode: lang, message: msg };
    }
  }

  if (hasUnsupportedAttachment(msg)) {
    return { outcome: "graceful_reject", reason: "unsupported_media", chatId, languageCode: lang };
  }

  if (msg.voice?.file_id) {
    return { outcome: "voice", chatId, message: msg };
  }

  if (msg.photo && msg.photo.length > 0) {
    return { outcome: "photo", chatId, message: msg };
  }

  if (text.length > 0) {
    if (text.length > MAX_TEXT) {
      return { outcome: "graceful_reject", reason: "message_too_long", chatId, languageCode: lang };
    }
    if (isEmojiOrSymbolOnlyText(text)) {
      return { outcome: "graceful_reject", reason: "emoji_only", chatId, languageCode: lang };
    }
    const mid = typeof msg.message_id === "number" ? msg.message_id : 0;
    return {
      outcome: "dialog_text",
      chatId,
      messageId: mid,
      text,
      languageCode: lang,
      message: msg,
    };
  }

  if (caption.length > 0) {
    // photo without caption handled above as photo; caption-only shouldn't happen without photo
    if (caption.length > MAX_TEXT) {
      return { outcome: "graceful_reject", reason: "message_too_long", chatId, languageCode: lang };
    }
  }

  return { outcome: "graceful_reject", reason: "empty_text", chatId, languageCode: lang };
}
