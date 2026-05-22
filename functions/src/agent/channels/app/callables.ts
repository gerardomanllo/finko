import { getStorage } from "firebase-admin/storage";
import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { geminiApiKey } from "../../../telegram/secrets";

function readGeminiApiKey(): string | undefined {
  try {
    const fromSecret = geminiApiKey.value();
    if (typeof fromSecret === "string" && fromSecret.trim().length > 0) {
      return fromSecret.trim();
    }
  } catch {
    // Emulator or missing secret binding — fall through to env.
  }
  const fromEnv = process.env.GEMINI_API_KEY?.trim();
  return fromEnv && fromEnv.length > 0 ? fromEnv : undefined;
}
import { AgentErrorKeys } from "../../core/statusKeys";
import {
  appendUserAgentMessage,
  dismissAgentMessage as dismissAgentMessageDoc,
  patchAssistantMessage,
} from "./messages";
import { runAppAgentTurn, startAssistantPlaceholder } from "./handleAppTurn";

function readUid(request: { auth?: { uid?: string } }): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  return uid;
}

function readString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return value.trim();
}

async function downloadStorageBytes(storagePath: string): Promise<{ bytes: Buffer; mime: string }> {
  const bucket = getStorage().bucket();
  const file = bucket.file(storagePath);
  const [buf] = await file.download();
  const [meta] = await file.getMetadata();
  const mime =
    typeof meta.contentType === "string" && meta.contentType.length > 0
      ? meta.contentType
      : "application/octet-stream";
  return { bytes: buf, mime };
}

async function finalizePlaceholderIfStuck(
  uid: string,
  placeholderId: string
): Promise<void> {
  const db = getFirestore();
  const ref = db.doc(`users/${uid}/agentMessages/${placeholderId}`);
  const snap = await ref.get();
  if (!snap.exists) return;
  if (snap.data()?.status === "processing") {
    await patchAssistantMessage(db, uid, placeholderId, {
      status: "failed",
      errorLabelKey: AgentErrorKeys.generic,
    });
  }
}

export const sendAgentMessage = onCall(
  { region: "us-central1", secrets: [geminiApiKey] },
  async (request) => {
    const uid = readUid(request);
    const data = request.data as Record<string, unknown>;
    const text = typeof data.text === "string" ? data.text.trim() : "";
    const storagePath =
      typeof data.storagePath === "string" ? data.storagePath.trim() : "";
    const kind = typeof data.kind === "string" ? data.kind.trim() : "text";
    const clientMessageId =
      typeof data.clientMessageId === "string" ? data.clientMessageId.trim() : undefined;

    if (!text && !storagePath) {
      throw new HttpsError("invalid-argument", "text or storagePath required.");
    }
    if (storagePath && !storagePath.startsWith(`users/${uid}/agentMedia/`)) {
      throw new HttpsError("invalid-argument", "Invalid storagePath.");
    }

    const db = getFirestore();
    const gemini = readGeminiApiKey();

    if (clientMessageId) {
      const dup = await db
        .collection(`users/${uid}/agentMessages`)
        .where("clientMessageId", "==", clientMessageId)
        .limit(1)
        .get();
      if (!dup.empty) {
        return { ok: true, userMessageId: dup.docs[0].id, duplicate: true };
      }
    }

    const userKind =
      kind === "image" || kind === "voice" ? (kind as "image" | "voice") : "text";
    const userMessageId = await appendUserAgentMessage(db, uid, {
      kind: userKind,
      ...(text ? { text } : {}),
      ...(storagePath ? { storagePath } : {}),
      ...(clientMessageId ? { clientMessageId } : {}),
    });

    const placeholderId = await startAssistantPlaceholder(db, uid);

    try {
      if (storagePath && userKind === "image") {
        const { bytes, mime } = await downloadStorageBytes(storagePath);
        await runAppAgentTurn(
          db,
          uid,
          { kind: "photo", bytes, mime, caption: text },
          gemini,
          placeholderId
        );
      } else if (storagePath && userKind === "voice") {
        const { bytes } = await downloadStorageBytes(storagePath);
        await runAppAgentTurn(db, uid, { kind: "voice", bytes }, gemini, placeholderId);
      } else {
        await runAppAgentTurn(db, uid, { kind: "text", text }, gemini, placeholderId);
      }
    } catch (e) {
      const errMsg = e instanceof Error ? e.message : String(e);
      const errStack = e instanceof Error ? e.stack : undefined;
      logger.error("sendAgentMessage failed", { uid, err: errMsg, stack: errStack });
      await patchAssistantMessage(db, uid, placeholderId, {
        status: "failed",
        errorLabelKey: AgentErrorKeys.generic,
      }).catch(() => undefined);
      throw new HttpsError("internal", "Agent failed to process message.", errMsg);
    }

    await finalizePlaceholderIfStuck(uid, placeholderId);

    return { ok: true, userMessageId, placeholderId };
  }
);

export const submitAgentAction = onCall(
  { region: "us-central1", secrets: [geminiApiKey] },
  async (request) => {
    const uid = readUid(request);
    const data = request.data as Record<string, unknown>;
    const callbackCode = readString(data.callbackCode, "callbackCode");

    const db = getFirestore();
    const gemini = readGeminiApiKey();
    const placeholderId = await startAssistantPlaceholder(db, uid);

    try {
      await runAppAgentTurn(
        db,
        uid,
        { kind: "callback", callbackCode },
        gemini,
        placeholderId
      );
    } catch (e) {
      logger.error("submitAgentAction failed", { uid, err: e });
      await patchAssistantMessage(db, uid, placeholderId, {
        status: "failed",
        errorLabelKey: AgentErrorKeys.generic,
      });
      throw new HttpsError("internal", "Agent action failed.");
    }

    await finalizePlaceholderIfStuck(uid, placeholderId);
    return { ok: true, placeholderId };
  }
);

export const dismissAgentMessage = onCall({ region: "us-central1" }, async (request) => {
  const uid = readUid(request);
  const data = request.data as Record<string, unknown>;
  const messageId = readString(data.messageId, "messageId");
  const db = getFirestore();
  await dismissAgentMessageDoc(db, uid, messageId);
  return { ok: true };
});
