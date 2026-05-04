import { FieldValue, Firestore, Transaction } from "firebase-admin/firestore";

import { TELEGRAM_CHAT_BINDINGS } from "./constants";

export function telegramChatBindingRef(db: Firestore, chatId: string) {
  return db.collection(TELEGRAM_CHAT_BINDINGS).doc(chatId);
}

export async function getUidForTelegramChat(
  db: Firestore,
  chatId: string
): Promise<string | null> {
  const snap = await telegramChatBindingRef(db, chatId).get();
  if (!snap.exists) return null;
  const uid = typeof snap.data()?.uid === "string" ? snap.data()!.uid.trim() : "";
  return uid.length > 0 ? uid : null;
}

export async function deleteTelegramChatBinding(db: Firestore, chatId: string): Promise<void> {
  await telegramChatBindingRef(db, chatId).delete().catch(() => undefined);
}

/** Upserts binding doc — same uid/chat pair expected during replay (/start twice). */
export function writeTelegramChatBindingTx(
  tx: Transaction,
  db: Firestore,
  chatId: string,
  uid: string
): void {
  tx.set(telegramChatBindingRef(db, chatId), {
    uid,
    updatedAt: FieldValue.serverTimestamp(),
  });
}
