import { createHash, randomInt } from "crypto";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { createLinkToken } from "./telegram/linkTokens";
import { telegramBotUsername } from "./telegram/secrets";
import {
  isLikelyE164,
  isLikelyTelegramUsername,
  normalizeTelegramUsername,
} from "./telegram/normalize";
import { readTelegramLinkState } from "./telegram/telegramLinkState";

const OTP_TTL_MS = 10 * 60 * 1000;

const DEV_PROJECT_IDS = new Set(["finkoappmx-dev"]);

function hashOtp(code: string): string {
  return createHash("sha256").update(code).digest("hex");
}

function readChannel(value: unknown): "whatsapp" | "telegram" {
  if (value === "whatsapp" || value === "telegram") {
    return value;
  }
  throw new HttpsError("invalid-argument", "Unsupported channel.");
}

function readIdentity(value: unknown): string {
  if (typeof value !== "string" || value.trim().length < 3) {
    throw new HttpsError("invalid-argument", "Identity is invalid.");
  }
  return value.trim();
}

function isDevProject(): boolean {
  const pid = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT ?? "";
  return DEV_PROJECT_IDS.has(pid);
}

function telegramIntegrationReady(data: Record<string, unknown> | undefined): boolean {
  const integrations = data?.integrations as Record<string, unknown> | undefined;
  const tg = integrations?.telegram as Record<string, unknown> | undefined;
  const chatId = typeof tg?.chatId === "string" ? tg.chatId : "";
  return Boolean(chatId && tg?.verifiedAt != null);
}

export const requestMessagingOtp = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const channel = readChannel(request.data?.channel);
  const identity = readIdentity(request.data?.identity);
  const db = getFirestore();

  if (channel === "telegram") {
    const trimmed = identity.trim();
    const isPhone = isLikelyE164(trimmed);
    const handle = isPhone ? trimmed : normalizeTelegramUsername(trimmed);
    if (!isPhone && !isLikelyTelegramUsername(handle)) {
      throw new HttpsError(
        "invalid-argument",
        "Enter a valid Telegram username or international phone number (+country…)."
      );
    }

    const linkState = await readTelegramLinkState(db, uid);
    if (!linkState?.chatId) {
      const botUser = telegramBotUsername.value().trim().replace(/^@+/, "");
      if (!botUser) {
        throw new HttpsError(
          "failed-precondition",
          "Telegram bot is not configured (missing TELEGRAM_BOT_USERNAME)."
        );
      }
      const token = await createLinkToken(db, uid);
      const startPayload = `link_${token}`;
      const deepLink = `tg://resolve?domain=${encodeURIComponent(botUser)}&start=${encodeURIComponent(startPayload)}`;
      return { ok: true, needsBotStart: true, deepLink };
    }

    if (
      !isPhone &&
      linkState.username &&
      handle &&
      linkState.username.toLowerCase() !== handle.toLowerCase()
    ) {
      throw new HttpsError(
        "invalid-argument",
        "That username does not match the Telegram account you linked. Disconnect and try again."
      );
    }

    // `integrations.telegram` is written only in `consumeLinkTokenAndBindChat`
    // (webhook transaction). Do not merge here — concurrent callable writes can
    // race the webhook and corrupt or duplicate-update the profile.
    return { ok: true, messagingReady: true };
  }

  // WhatsApp — OTP challenge (unchanged shape).
  const challengeId = `${channel}:${identity.toLowerCase()}`;
  const code = `${randomInt(100000, 999999)}`;
  await db.doc(`users/${uid}/_otpChallenges/${challengeId}`).set({
    channel,
    identity,
    otpHash: hashOtp(code),
    createdAt: FieldValue.serverTimestamp(),
    expiresAtMs: Date.now() + OTP_TTL_MS,
    attempts: 0,
    verified: false,
  });

  if (isDevProject()) {
    return { ok: true, challengeId, debugOtpCode: code };
  }
  return { ok: true, challengeId };
});

export const verifyMessagingOtp = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const channel = readChannel(request.data?.channel);
  const db = getFirestore();

  if (channel === "telegram") {
    const userRef = db.doc(`users/${uid}`);
    const userSnap = await userRef.get();
    if (telegramIntegrationReady(userSnap.data() as Record<string, unknown> | undefined)) {
      return { ok: true };
    }
    throw new HttpsError(
      "failed-precondition",
      "Telegram is not connected yet. Open the link from the Finko app and tap Start in the bot."
    );
  }

  const identity = readIdentity(request.data?.identity);
  const otpCode = readIdentity(request.data?.otpCode);
  const challengeId = `${channel}:${identity.toLowerCase()}`;
  const challengeRef = db.doc(`users/${uid}/_otpChallenges/${challengeId}`);
  const challenge = await challengeRef.get();
  if (!challenge.exists) {
    throw new HttpsError("not-found", "OTP challenge not found.");
  }
  const data = challenge.data() as Record<string, unknown>;
  if (typeof data.expiresAtMs === "number" && data.expiresAtMs < Date.now()) {
    throw new HttpsError("deadline-exceeded", "OTP expired.");
  }

  const expectedHash = data.otpHash as string | undefined;
  if (expectedHash !== hashOtp(otpCode)) {
    await challengeRef.set(
      {
        attempts: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    throw new HttpsError("permission-denied", "OTP mismatch.");
  }

  const userRef = db.doc(`users/${uid}`);
  await userRef.set(
    {
      integrations: {
        whatsapp: {
          phoneE164: identity,
          verifiedAt: FieldValue.serverTimestamp(),
        },
      },
    },
    { merge: true }
  );

  await challengeRef.set(
    {
      verified: true,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return { ok: true };
});
