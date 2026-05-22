import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

import { APP_AGENT_SESSIONS, BOT_SESSION_TTL_MS, TELEGRAM_BOT_SESSIONS } from "./constants";
import type { TelegramMessage } from "./types";

export type BotLocale = "es" | "en";

export type BotIntent =
  | "idle"
  | "expense"
  | "income"
  | "transfer"
  | "await_transfer_from"
  | "await_transfer_to"
  | "await_transfer_amount"
  | "await_recurring_cadence";

export type TelegramBotSessionDoc = {
  uid: string;
  locale: BotLocale;
  intent: BotIntent;
  step: string;
  draft: Record<string, unknown>;
  expiresAt: Timestamp;
  updatedAt: FirebaseFirestore.FieldValue;
  lastPromptMessageId?: number;
};

export function sessionCollectionForChatId(chatId: string): string {
  return chatId.startsWith("app_") ? APP_AGENT_SESSIONS : TELEGRAM_BOT_SESSIONS;
}

export function botSessionRef(db: Firestore, chatId: string) {
  return db.collection(sessionCollectionForChatId(chatId)).doc(
    chatId.startsWith("app_") ? chatId.slice(4) : chatId
  );
}

export function telegramBotSessionRef(db: Firestore, chatId: string) {
  return botSessionRef(db, chatId);
}

/** Omit `undefined` recursively — Firestore rejects undefined field values (dynamic `draft`). */
function stripUndefinedDeep(input: unknown): unknown {
  if (input === undefined) return undefined;
  if (input === null || typeof input !== "object") return input;
  if (Array.isArray(input)) {
    return input.map((item) => stripUndefinedDeep(item));
  }
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(input as Record<string, unknown>)) {
    const sv = stripUndefinedDeep(v);
    if (sv !== undefined) out[k] = sv;
  }
  return out;
}

export async function loadTelegramBotSession(
  db: Firestore,
  chatId: string
): Promise<TelegramBotSessionDoc | null> {
  const snap = await botSessionRef(db, chatId).get();
  if (!snap.exists) return null;
  const d = snap.data() as TelegramBotSessionDoc;
  if (!d.uid || typeof d.uid !== "string") return null;
  const exp = d.expiresAt as Timestamp | undefined;
  if (exp && exp.toMillis() < Date.now()) {
    await botSessionRef(db, chatId).delete().catch(() => undefined);
    return null;
  }
  return d;
}

/** Telegram client language only; prefer [pickBotLocale] for bot replies. */
export function resolveBotLocaleFromTelegram(message?: TelegramMessage): BotLocale {
  const code = message?.from?.language_code?.trim().toLowerCase() ?? "";
  if (code.startsWith("es")) return "es";
  if (code.startsWith("en")) return "en";
  return "es";
}

export async function upsertTelegramBotSession(
  db: Firestore,
  chatId: string,
  partial: Omit<TelegramBotSessionDoc, "expiresAt" | "updatedAt"> &
    Partial<Pick<TelegramBotSessionDoc, "expiresAt">>
): Promise<void> {
  const expiresAt =
    partial.expiresAt ?? Timestamp.fromMillis(Date.now() + BOT_SESSION_TTL_MS);
  await botSessionRef(db, chatId).set(
    {
      ...partial,
      draft: stripUndefinedDeep(partial.draft) as Record<string, unknown>,
      expiresAt,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

export async function deleteTelegramBotSession(db: Firestore, chatId: string): Promise<void> {
  await botSessionRef(db, chatId).delete().catch(() => undefined);
}
