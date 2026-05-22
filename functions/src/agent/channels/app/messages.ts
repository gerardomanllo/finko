import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";

export type AgentMessageRole = "user" | "assistant" | "system";
export type AgentMessageKind = "text" | "image" | "voice" | "system";
export type AgentMessageStatus =
  | "pending"
  | "processing"
  | "complete"
  | "failed"
  | "superseded";

export type AgentActionChip = {
  id: string;
  label: string;
  callbackCode: string;
};

export type AgentMessageDoc = {
  role: AgentMessageRole;
  kind: AgentMessageKind;
  text?: string;
  storagePath?: string;
  mimeType?: string;
  durationMs?: number;
  actions?: AgentActionChip[];
  status?: AgentMessageStatus;
  statusLabelKey?: string;
  errorLabelKey?: string;
  dismissedAt?: Timestamp;
  clientMessageId?: string;
  createdAt: FirebaseFirestore.FieldValue;
  updatedAt: FirebaseFirestore.FieldValue;
};

function agentMessagesCol(db: Firestore, uid: string) {
  return db.collection(`users/${uid}/agentMessages`);
}

/** Firestore rejects `undefined` field values. */
function omitUndefined<T extends Record<string, unknown>>(obj: T): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined) out[k] = v;
  }
  return out;
}

export async function supersedeFailedAgentMessages(db: Firestore, uid: string): Promise<void> {
  const snap = await agentMessagesCol(db, uid)
    .where("status", "==", "failed")
    .limit(50)
    .get();
  const batch = db.batch();
  for (const doc of snap.docs) {
    batch.update(doc.ref, {
      status: "superseded",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  if (!snap.empty) await batch.commit();
}

export async function appendUserAgentMessage(
  db: Firestore,
  uid: string,
  partial: Omit<AgentMessageDoc, "createdAt" | "updatedAt" | "role"> & {
    role?: AgentMessageRole;
  }
): Promise<string> {
  const ref = agentMessagesCol(db, uid).doc();
  await ref.set({
    ...omitUndefined({
      role: "user",
      status: "complete",
      ...partial,
    }),
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

export async function createAssistantPlaceholder(
  db: Firestore,
  uid: string,
  statusLabelKey: string
): Promise<string> {
  const ref = agentMessagesCol(db, uid).doc();
  await ref.set({
    role: "assistant",
    kind: "text",
    status: "processing",
    statusLabelKey,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

export async function patchAssistantMessage(
  db: Firestore,
  uid: string,
  messageId: string,
  patch: Partial<
    Pick<
      AgentMessageDoc,
      | "text"
      | "actions"
      | "status"
      | "statusLabelKey"
      | "errorLabelKey"
      | "dismissedAt"
    >
  >
): Promise<void> {
  await agentMessagesCol(db, uid)
    .doc(messageId)
    .set(
      {
        ...omitUndefined(patch as Record<string, unknown>),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
}

export async function dismissAgentMessage(
  db: Firestore,
  uid: string,
  messageId: string
): Promise<void> {
  const ref = agentMessagesCol(db, uid).doc(messageId);
  const snap = await ref.get();
  if (!snap.exists) return;
  const status = snap.data()?.status as string | undefined;
  if (status !== "failed" && status !== "superseded") {
    return;
  }
  await ref.set(
    {
      dismissedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

/** Parse Telegram inline keyboard rows into action chips. */
export function actionsFromReplyMarkup(markup: unknown): AgentActionChip[] | undefined {
  if (!markup || typeof markup !== "object") return undefined;
  const im = (markup as { inline_keyboard?: unknown }).inline_keyboard;
  if (!Array.isArray(im)) return undefined;
  const out: AgentActionChip[] = [];
  let idx = 0;
  for (const row of im) {
    if (!Array.isArray(row)) continue;
    for (const btn of row) {
      if (!btn || typeof btn !== "object") continue;
      const text = typeof (btn as { text?: string }).text === "string" ? (btn as { text: string }).text : "";
      const code =
        typeof (btn as { callback_data?: string }).callback_data === "string"
          ? (btn as { callback_data: string }).callback_data
          : "";
      if (!text || !code) continue;
      out.push({ id: `a${idx++}`, label: text, callbackCode: code });
    }
  }
  return out.length > 0 ? out : undefined;
}
