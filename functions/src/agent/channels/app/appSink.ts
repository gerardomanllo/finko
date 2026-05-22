import { FieldValue, type Firestore } from "firebase-admin/firestore";

import { AgentErrorKeys, AgentStatusKeys } from "../../core/statusKeys";
import {
  actionsFromReplyMarkup,
  patchAssistantMessage,
  type AgentActionChip,
} from "./messages";

export type AppAgentSink = {
  uid: string;
  placeholderId: string;
  onStatus: (statusLabelKey: string) => Promise<void>;
  appendReply: (text: string, actions?: AgentActionChip[]) => Promise<void>;
  markFailed: (errorLabelKey: string) => Promise<void>;
};

export function createAppAgentSink(
  db: Firestore,
  uid: string,
  placeholderId: string
): AppAgentSink {
  let placeholderOpen = true;

  async function appendCompleteDoc(text: string, actions?: AgentActionChip[]) {
    const doc: Record<string, unknown> = {
      role: "assistant",
      kind: "text",
      text,
      status: "complete",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (actions != null && actions.length > 0) {
      doc.actions = actions;
    }
    await db.collection(`users/${uid}/agentMessages`).add(doc);
  }

  return {
    uid,
    placeholderId,
    async onStatus(statusLabelKey: string) {
      await patchAssistantMessage(db, uid, placeholderId, {
        status: "processing",
        statusLabelKey,
      });
    },
    async appendReply(text: string, actions?: AgentActionChip[]) {
      if (placeholderOpen) {
        placeholderOpen = false;
        await db.doc(`users/${uid}/agentMessages/${placeholderId}`).update({
          text,
          actions: actions ?? FieldValue.delete(),
          status: "complete",
          statusLabelKey: FieldValue.delete(),
          errorLabelKey: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return;
      }
      await appendCompleteDoc(text, actions);
    },
    async markFailed(errorLabelKey: string) {
      placeholderOpen = false;
      await db.doc(`users/${uid}/agentMessages/${placeholderId}`).update({
        status: "failed",
        errorLabelKey: errorLabelKey || AgentErrorKeys.generic,
        statusLabelKey: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    },
  };
}

/** Intercepts Telegram Bot API HTTP calls and writes agent thread replies instead. */
export function createAppInterceptFetch(
  baseFetch: typeof fetch,
  sink: AppAgentSink
): typeof fetch {
  return async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    if (url.includes("api.telegram.org") && init?.method === "POST" && typeof init.body === "string") {
      try {
        const parsed = JSON.parse(init.body) as Record<string, unknown>;
        const method = url.split("/").pop() ?? "";
        if (method === "sendMessage" && typeof parsed.text === "string") {
          const actions = actionsFromReplyMarkup(parsed.reply_markup);
          await sink.appendReply(parsed.text, actions);
          return new Response(JSON.stringify({ ok: true, result: { message_id: 1 } }), {
            status: 200,
            headers: { "Content-Type": "application/json" },
          });
        }
        if (method === "editMessageText" && typeof parsed.text === "string") {
          const actions = actionsFromReplyMarkup(parsed.reply_markup);
          await sink.appendReply(parsed.text, actions);
          return new Response(JSON.stringify({ ok: true }), {
            status: 200,
            headers: { "Content-Type": "application/json" },
          });
        }
        if (method === "answerCallbackQuery") {
          return new Response(JSON.stringify({ ok: true }), {
            status: 200,
            headers: { "Content-Type": "application/json" },
          });
        }
      } catch {
        await sink.markFailed(AgentErrorKeys.generic);
      }
    }
    return baseFetch(input, init);
  };
}

export function mapProcessingTelegramKeyToStatusKey(i18nKey: string): string {
  if (i18nKey.includes("photo")) return AgentStatusKeys.readingReceipt;
  if (i18nKey.includes("voice")) return AgentStatusKeys.transcribing;
  return AgentStatusKeys.thinking;
}
