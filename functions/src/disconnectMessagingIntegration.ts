import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { deleteTelegramLinkState } from "./telegram/telegramLinkState";

function readChannel(value: unknown): "whatsapp" | "telegram" {
  if (value === "whatsapp" || value === "telegram") {
    return value;
  }
  throw new HttpsError("invalid-argument", "Unsupported channel.");
}

export const disconnectMessagingIntegration = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const channel = readChannel(request.data?.channel);
  const db = getFirestore();
  const userRef = db.doc(`users/${uid}`);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    return { ok: true };
  }

  if (channel === "telegram") {
    await deleteTelegramLinkState(db, uid);
    await userRef.update({
      "integrations.telegram": FieldValue.delete(),
    });
    return { ok: true };
  }

  const data = userSnap.data() as Record<string, unknown> | undefined;
  const integrations = data?.integrations as Record<string, unknown> | undefined;
  const wa = integrations?.whatsapp as Record<string, unknown> | undefined;
  const phoneE164 = typeof wa?.phoneE164 === "string" ? wa.phoneE164.trim() : "";
  if (phoneE164) {
    const challengeId = `whatsapp:${phoneE164.toLowerCase()}`;
    await db.doc(`users/${uid}/_otpChallenges/${challengeId}`).delete();
  }

  await userRef.update({
    "integrations.whatsapp": FieldValue.delete(),
  });
  return { ok: true };
});
