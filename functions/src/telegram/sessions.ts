import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

import { BOT_SESSION_TTL_MS, TELEGRAM_BOT_SESSIONS } from "./constants";
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

export function telegramBotSessionRef(db: Firestore, chatId: string) {
  return db.collection(TELEGRAM_BOT_SESSIONS).doc(chatId);
}

export async function loadTelegramBotSession(
  db: Firestore,
  chatId: string
): Promise<TelegramBotSessionDoc | null> {
  const snap = await telegramBotSessionRef(db, chatId).get();
  if (!snap.exists) return null;
  const d = snap.data() as TelegramBotSessionDoc;
  if (!d.uid || typeof d.uid !== "string") return null;
  const exp = d.expiresAt as Timestamp | undefined;
  if (exp && exp.toMillis() < Date.now()) {
    await telegramBotSessionRef(db, chatId).delete().catch(() => undefined);
    return null;
  }
  return d;
}

export function resolveBotLocaleFromTelegram(message?: TelegramMessage): BotLocale {
  const code = message?.from?.language_code?.trim().toLowerCase() ?? "";
  if (code.startsWith("es")) return "es";
  return "en";
}

export async function upsertTelegramBotSession(
  db: Firestore,
  chatId: string,
  partial: Omit<TelegramBotSessionDoc, "expiresAt" | "updatedAt"> &
    Partial<Pick<TelegramBotSessionDoc, "expiresAt">>
): Promise<void> {
  const expiresAt =
    partial.expiresAt ?? Timestamp.fromMillis(Date.now() + BOT_SESSION_TTL_MS);
  await telegramBotSessionRef(db, chatId).set(
    {
      ...partial,
      expiresAt,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

export async function deleteTelegramBotSession(db: Firestore, chatId: string): Promise<void> {
  await telegramBotSessionRef(db, chatId).delete().catch(() => undefined);
}
