import { randomBytes } from "crypto";
import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

import { LINK_TOKEN_TTL_MS, TELEGRAM_LINK_TOKENS } from "./constants";
import { writeTelegramChatBindingTx } from "./chatBindings";
import { telegramLinkStateRef } from "./telegramLinkState";

export type LinkTokenDoc = {
  uid: string;
  expiresAt: Timestamp;
  used: boolean;
  createdAt: FirebaseFirestore.FieldValue;
};

/** Lowercase hex only — safe for Telegram `?start=` payloads (a–z, 0–9). */
export function newLinkToken(): string {
  return randomBytes(16).toString("hex");
}

export function linkTokenRef(db: Firestore, token: string) {
  return db.collection(TELEGRAM_LINK_TOKENS).doc(token);
}

export async function createLinkToken(db: Firestore, uid: string): Promise<string> {
  const token = newLinkToken();
  const expiresAt = Timestamp.fromMillis(Date.now() + LINK_TOKEN_TTL_MS);
  await linkTokenRef(db, token).set({
    uid,
    expiresAt,
    used: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  return token;
}

/**
 * Atomically validates the link token, writes `users/{uid}/_telegramLink/state`,
 * **`integrations.telegram`** on `users/{uid}`, and marks the token used.
 * Idempotent: if the token was already used for the same `chatId`, returns success (no extra writes).
 */
export type LinkBindFailureReason = "missing" | "expired" | "used_other" | "invalid" | "unknown";

export type ConsumeLinkTokenResult =
  | { ok: true; uid: string }
  | { ok: false; reason: LinkBindFailureReason };

export async function consumeLinkTokenAndBindChat(
  db: Firestore,
  token: string,
  chatId: string,
  usernameNorm: string
): Promise<ConsumeLinkTokenResult> {
  const tokenRef = linkTokenRef(db, token);

  try {
    const uid = await db.runTransaction(async (tx) => {
      const snap = await tx.get(tokenRef);
      if (!snap.exists) {
        throw new Error("missing");
      }
      const data = snap.data() as Record<string, unknown>;
      const uidInner = typeof data.uid === "string" ? data.uid : "";
      if (!uidInner) {
        throw new Error("nouid");
      }

      const exp = data.expiresAt as Timestamp | undefined;
      if (exp && exp.toMillis() < Date.now()) {
        throw new Error("expired");
      }

      const used = data.used === true;
      const stateRef = telegramLinkStateRef(db, uidInner);
      const stateSnap = await tx.get(stateRef);
      const existingChat =
        stateSnap.exists && typeof (stateSnap.data() as Record<string, unknown>).chatId === "string"
          ? String((stateSnap.data() as Record<string, unknown>).chatId)
          : "";

      if (used) {
        if (existingChat === chatId) {
          writeTelegramChatBindingTx(tx, db, chatId, uidInner);
          return uidInner;
        }
        throw new Error("used");
      }

      const userRef = db.doc(`users/${uidInner}`);
      await tx.get(userRef);

      tx.set(
        stateRef,
        {
          chatId,
          username: usernameNorm,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      tx.set(
        tokenRef,
        {
          used: true,
          usedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      tx.set(
        userRef,
        {
          integrations: {
            telegram: {
              username: usernameNorm,
              chatId,
              verifiedAt: FieldValue.serverTimestamp(),
            },
          },
        },
        { merge: true }
      );
      writeTelegramChatBindingTx(tx, db, chatId, uidInner);
      return uidInner;
    });
    return { ok: true, uid };
  } catch (e) {
    const msg = e instanceof Error ? e.message : "";
    if (msg === "missing") return { ok: false, reason: "missing" };
    if (msg === "expired") return { ok: false, reason: "expired" };
    if (msg === "used") return { ok: false, reason: "used_other" };
    if (msg === "nouid") return { ok: false, reason: "invalid" };
    return { ok: false, reason: "unknown" };
  }
}

/** @deprecated Prefer consumeLinkTokenAndBindChat for webhook path. */
export async function consumeLinkToken(
  db: Firestore,
  token: string
): Promise<{ uid: string } | null> {
  const ref = linkTokenRef(db, token);
  const snap = await ref.get();
  if (!snap.exists) {
    return null;
  }
  const data = snap.data() as Record<string, unknown>;
  if (data.used === true) {
    return null;
  }
  const exp = data.expiresAt as Timestamp | undefined;
  if (exp && exp.toMillis() < Date.now()) {
    return null;
  }
  const uid = typeof data.uid === "string" ? data.uid : "";
  if (!uid) {
    return null;
  }
  await ref.set({ used: true, usedAt: FieldValue.serverTimestamp() }, { merge: true });
  return { uid };
}
