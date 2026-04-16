import { createHash, randomInt } from "crypto";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const OTP_TTL_MS = 10 * 60 * 1000;

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

export const requestMessagingOtp = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const channel = readChannel(request.data?.channel);
  const identity = readIdentity(request.data?.identity);

  const challengeId = `${channel}:${identity.toLowerCase()}`;
  const code = `${randomInt(100000, 999999)}`;
  await getFirestore().doc(`users/${uid}/_otpChallenges/${challengeId}`).set({
    channel,
    identity,
    otpHash: hashOtp(code),
    createdAt: FieldValue.serverTimestamp(),
    expiresAtMs: Date.now() + OTP_TTL_MS,
    attempts: 0,
    verified: false,
  });

  // For dev/testing this callable returns the code. Production can remove this.
  return { ok: true, challengeId, debugOtpCode: code };
});

export const verifyMessagingOtp = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const channel = readChannel(request.data?.channel);
  const identity = readIdentity(request.data?.identity);
  const otpCode = readIdentity(request.data?.otpCode);

  const challengeId = `${channel}:${identity.toLowerCase()}`;
  const challengeRef = getFirestore().doc(`users/${uid}/_otpChallenges/${challengeId}`);
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

  const userRef = getFirestore().doc(`users/${uid}`);
  if (channel === "whatsapp") {
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
  } else {
    await userRef.set(
      {
        integrations: {
          telegram: {
            username: identity,
            verifiedAt: FieldValue.serverTimestamp(),
          },
        },
      },
      { merge: true }
    );
  }
  await challengeRef.set(
    {
      verified: true,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return { ok: true };
});
