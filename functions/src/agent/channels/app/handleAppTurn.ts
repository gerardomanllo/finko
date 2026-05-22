import * as logger from "firebase-functions/logger";
import type { Firestore } from "firebase-admin/firestore";

import {
  handleCallback,
  handleDialogText,
  type TelegramHandleDeps,
} from "../../../telegram/handleUpdate";
import { loadAgentPreferences } from "../../../telegram/ledgerToolkit";
import { pickBotLocale } from "../../../telegram/localeInference";
import { t, type MessageKey } from "../../../telegram/i18n";
import type { TelegramCallbackQuery, TelegramMessage } from "../../../telegram/types";
import { isEmojiOrSymbolOnlyText } from "../../../telegram/classifyUpdate";
import { TELEGRAM_MAX_TEXT_CHARS } from "../../../telegram/constants";
import { AgentErrorKeys, AgentStatusKeys } from "../../core/statusKeys";
import { createAppAgentSink, createAppInterceptFetch } from "./appSink";
import { handleAppPhotoBytes, handleAppVoiceBytes } from "./mediaHandlers";
import {
  createAssistantPlaceholder,
  supersedeFailedAgentMessages,
} from "./messages";

export function appChatIdForUid(uid: string): { chatIdStr: string; chatIdNum: number } {
  const chatIdStr = `app_${uid}`;
  let h = 0;
  for (let i = 0; i < uid.length; i++) {
    h = (Math.imul(31, h) + uid.charCodeAt(i)) | 0;
  }
  const chatIdNum = Math.abs(h) || 1;
  return { chatIdStr, chatIdNum };
}

function stubMessage(chatIdNum: number): TelegramMessage {
  return {
    message_id: 1,
    chat: { id: chatIdNum, type: "private" },
    date: Math.floor(Date.now() / 1000),
  };
}

export type AppTextTurn = { kind: "text"; text: string };
export type AppCallbackTurn = { kind: "callback"; callbackCode: string };
export type AppPhotoTurn = { kind: "photo"; bytes: Buffer; mime: string; caption?: string };
export type AppVoiceTurn = { kind: "voice"; bytes: Buffer };

export type AppAgentTurn = AppTextTurn | AppCallbackTurn | AppPhotoTurn | AppVoiceTurn;

export async function runAppAgentTurn(
  db: Firestore,
  uid: string,
  turn: AppAgentTurn,
  geminiApiKey: string | undefined,
  placeholderId: string
): Promise<void> {
  const { chatIdStr, chatIdNum } = appChatIdForUid(uid);
  const sink = createAppAgentSink(db, uid, placeholderId);
  const deps: TelegramHandleDeps = {
    db,
    fetchTelegram: createAppInterceptFetch(fetch, sink),
    botToken: "app",
    geminiApiKey,
  };

  await supersedeFailedAgentMessages(db, uid);
  const prefs = await loadAgentPreferences(db, uid);

  try {
    if (turn.kind === "text") {
      const text = turn.text.trim();
      if (text.length === 0) {
        await sink.markFailed(AgentErrorKeys.generic);
        return;
      }
      if (text.length > TELEGRAM_MAX_TEXT_CHARS) {
        await sink.appendReply(
          t(pickBotLocale({ localeOverride: prefs.localeOverride }), "message_too_long")
        );
        return;
      }
      if (isEmojiOrSymbolOnlyText(text)) {
        await sink.appendReply(
          t(pickBotLocale({ localeOverride: prefs.localeOverride }), "emoji_only")
        );
        return;
      }
      await sink.onStatus(AgentStatusKeys.receiving);
      await handleDialogText(
        uid,
        chatIdStr,
        chatIdNum,
        prefs,
        text,
        stubMessage(chatIdNum),
        deps
      );
      return;
    }

    if (turn.kind === "callback") {
      await sink.onStatus(AgentStatusKeys.thinking);
      const cq: TelegramCallbackQuery = {
        id: `app_${Date.now()}`,
        from: { id: chatIdNum },
        message: stubMessage(chatIdNum),
        data: turn.callbackCode,
      };
      const locale = pickBotLocale({ localeOverride: prefs.localeOverride });
      await handleCallback(uid, chatIdStr, chatIdNum, locale, cq, deps);
      return;
    }

    if (turn.kind === "photo") {
      await handleAppPhotoBytes(
        uid,
        chatIdStr,
        chatIdNum,
        turn.bytes,
        turn.mime,
        turn.caption ?? "",
        deps,
        sink
      );
      return;
    }

    if (turn.kind === "voice") {
      await handleAppVoiceBytes(uid, chatIdStr, chatIdNum, turn.bytes, deps, sink);
    }
  } catch (e) {
    logger.error("runAppAgentTurn failed", {
      uid,
      kind: turn.kind,
      err: e instanceof Error ? e.message : String(e),
      stack: e instanceof Error ? e.stack : undefined,
    });
    const loc = pickBotLocale({ localeOverride: prefs.localeOverride });
    const key: MessageKey = "generic_error";
    try {
      await sink.appendReply(t(loc, key));
    } catch (sendErr) {
      await sink.markFailed(AgentErrorKeys.generic);
      throw sendErr;
    }
  }

  await ensurePlaceholderResolved(db, uid, placeholderId, sink);
}

async function ensurePlaceholderResolved(
  db: Firestore,
  uid: string,
  placeholderId: string,
  sink: ReturnType<typeof createAppAgentSink>
): Promise<void> {
  const snap = await db.doc(`users/${uid}/agentMessages/${placeholderId}`).get();
  if (snap.data()?.status !== "processing") return;
  await sink.markFailed(AgentErrorKeys.generic);
}

export async function startAssistantPlaceholder(
  db: Firestore,
  uid: string
): Promise<string> {
  return createAssistantPlaceholder(db, uid, AgentStatusKeys.receiving);
}
