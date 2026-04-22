import { FieldValue, Firestore } from "firebase-admin/firestore";

import {
  TELEGRAM_LINK_STATE_DOC,
  TELEGRAM_LINK_SUBCOLLECTION,
} from "./constants";

export type TelegramLinkState = {
  chatId: string;
  username: string;
};

export function telegramLinkStateRef(db: Firestore, uid: string) {
  return db.doc(`users/${uid}/${TELEGRAM_LINK_SUBCOLLECTION}/${TELEGRAM_LINK_STATE_DOC}`);
}

export async function readTelegramLinkState(
  db: Firestore,
  uid: string
): Promise<{ chatId: string; username: string } | null> {
  const snap = await telegramLinkStateRef(db, uid).get();
  if (!snap.exists) {
    return null;
  }
  const d = snap.data() as Record<string, unknown>;
  const chatId = typeof d.chatId === "string" ? d.chatId : String(d.chatId ?? "");
  const username = typeof d.username === "string" ? d.username : "";
  if (!chatId) {
    return null;
  }
  return {
    chatId,
    username,
  };
}

export async function setTelegramLinkState(
  db: Firestore,
  uid: string,
  data: { chatId: string; username: string }
): Promise<void> {
  await telegramLinkStateRef(db, uid).set(
    {
      chatId: data.chatId,
      username: data.username,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

export async function deleteTelegramLinkState(db: Firestore, uid: string): Promise<void> {
  await telegramLinkStateRef(db, uid).delete();
}
