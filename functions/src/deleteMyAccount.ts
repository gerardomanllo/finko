import type { Auth } from "firebase-admin/auth";
import { getAuth } from "firebase-admin/auth";
import type { Firestore } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { deleteTelegramChatBinding } from "./telegram/chatBindings";
import { deleteTelegramBotSession } from "./telegram/sessions";
import { deleteTelegramLinkState } from "./telegram/telegramLinkState";

/**
 * Deletes all Firestore data under `users/{uid}`, Telegram server-side binding
 * docs when linked, then the Firebase Auth user. Exported for unit tests.
 */
export async function deleteMyAccountForUid(
  db: Firestore,
  auth: Auth,
  uid: string
): Promise<void> {
  const userRef = db.doc(`users/${uid}`);
  const userSnap = await userRef.get();

  if (userSnap.exists) {
    const data = userSnap.data() as Record<string, unknown> | undefined;
    const integrations = data?.integrations as Record<string, unknown> | undefined;
    const tg = integrations?.telegram as Record<string, unknown> | undefined;
    const chatId = typeof tg?.chatId === "string" ? tg.chatId.trim() : "";
    if (chatId) {
      await deleteTelegramChatBinding(db, chatId);
      await deleteTelegramBotSession(db, chatId);
    }
  }

  await deleteTelegramLinkState(db, uid);
  await db.recursiveDelete(userRef);

  try {
    await auth.deleteUser(uid);
  } catch (e: unknown) {
    const code = typeof e === "object" && e !== null && "code" in e ? String((e as { code?: string }).code) : "";
    if (code === "auth/user-not-found") {
      return;
    }
    throw e;
  }
}

export const deleteMyAccount = onCall(
  { region: "us-central1", timeoutSeconds: 540, memory: "512MiB" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;
    try {
      await deleteMyAccountForUid(getFirestore(), getAuth(), uid);
    } catch (e: unknown) {
      logger.error("deleteMyAccount failed", { uid, err: e });
      throw new HttpsError("internal", "Account deletion failed.");
    }
    return { ok: true };
  }
);
