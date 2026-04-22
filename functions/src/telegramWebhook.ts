import { getFirestore } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { consumeLinkTokenAndBindChat } from "./telegram/linkTokens";
import { telegramStartLinkTokenFromMessageText } from "./telegram/parseTelegramStart";
import {
  telegramBotToken,
  telegramWebhookDevBypass,
  telegramWebhookSecret,
} from "./telegram/secrets";

type TelegramUpdate = {
  update_id?: number;
  message?: {
    text?: string;
    chat?: { id?: number; username?: string };
  };
};

/** Short preview for Logs Explorer (avoid huge or binary bodies). */
function textPreview(s: string, max = 120): string {
  const oneLine = s.replace(/\s+/g, " ").trim();
  return oneLine.length <= max ? oneLine : `${oneLine.slice(0, max)}…`;
}

export const telegramWebhook = onRequest(
  {
    region: "us-central1",
    secrets: [telegramBotToken, telegramWebhookSecret],
    cors: false,
    invoker: "public",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      logger.warn("telegramWebhook: rejected non-POST", { method: req.method });
      res.status(405).send("Method Not Allowed");
      return;
    }

    const expected = telegramWebhookSecret.value();
    const got = req.get("x-telegram-bot-api-secret-token") ?? "";
    const bypass = telegramWebhookDevBypass.value() === "true";
    if (!bypass && (!expected || got !== expected)) {
      logger.warn("telegramWebhook: forbidden (secret mismatch or missing)", {
        bypass,
        secretConfigured: Boolean(expected),
        secretHeaderPresent: got.length > 0,
        secretHeaderLength: got.length,
      });
      res.status(403).send("Forbidden");
      return;
    }

    let update: TelegramUpdate;
    try {
      update = req.body as TelegramUpdate;
    } catch (e) {
      logger.error("telegramWebhook: bad body", e);
      res.status(400).send("Bad Request");
      return;
    }

    const updateId = update.update_id;
    const topKeys =
      update && typeof update === "object" ? Object.keys(update as object) : [];

    logger.info("telegramWebhook: update received", {
      updateId,
      topLevelKeys: topKeys,
      hasMessage: Boolean(update.message),
    });

    const text = update.message?.text;
    const chatIdNum = update.message?.chat?.id;
    if (typeof text !== "string" || typeof chatIdNum !== "number") {
      logger.info("telegramWebhook: ignored (no processable message)", {
        updateId,
        hasText: typeof text === "string",
        hasChatId: typeof chatIdNum === "number",
        topLevelKeys: topKeys,
      });
      res.status(200).json({ ok: true });
      return;
    }

    const token = telegramStartLinkTokenFromMessageText(text);
    if (!token) {
      logger.info("telegramWebhook: no link token in message (ok)", {
        updateId,
        chatId: chatIdNum,
        textLen: text.length,
        textPreview: textPreview(text),
        startsWithStart: text.trimStart().toLowerCase().startsWith("/start"),
      });
      res.status(200).json({ ok: true });
      return;
    }

    const db = getFirestore();
    const tgUsername = update.message?.chat?.username;
    const usernameNorm = typeof tgUsername === "string" ? tgUsername.toLowerCase() : "";
    const chatIdStr = String(chatIdNum);

    logger.info("telegramWebhook: parsed link token", {
      updateId,
      chatId: chatIdNum,
      tokenPrefix: `${token.slice(0, 8)}…`,
      telegramUsername: usernameNorm || undefined,
    });

    const bound = await consumeLinkTokenAndBindChat(db, token, chatIdStr, usernameNorm);
    if (!bound.ok) {
      logger.warn("telegramWebhook: bind failed (invalid, expired, or conflicting token)", {
        updateId,
        chatId: chatIdNum,
        tokenPrefix: token.slice(0, 8),
      });
      res.status(200).json({ ok: true });
      return;
    }

    logger.info("telegramWebhook: linked chat to user", {
      updateId,
      chatId: chatIdNum,
      uid: bound.uid,
      tokenPrefix: `${token.slice(0, 8)}…`,
    });

    // Acknowledge user in Telegram (best-effort).
    try {
      const tok = telegramBotToken.value();
      if (tok) {
        const dmRes = await fetch(`https://api.telegram.org/bot${tok}/sendMessage`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            chat_id: chatIdNum,
            text:
              "Finko: Telegram is connected to your account. You can return to the app and continue.",
            disable_web_page_preview: true,
          }),
        });
        const dmBody = await dmRes.text();
        if (!dmRes.ok) {
          logger.warn("telegramWebhook: sendMessage non-OK", {
            updateId,
            chatId: chatIdNum,
            status: dmRes.status,
            bodyPreview: textPreview(dmBody, 200),
          });
        } else {
          logger.info("telegramWebhook: sendMessage ok", {
            updateId,
            chatId: chatIdNum,
          });
        }
      } else {
        logger.warn("telegramWebhook: skip sendMessage (bot token empty)", {
          updateId,
          chatId: chatIdNum,
        });
      }
    } catch (e) {
      logger.error("telegramWebhook: follow-up sendMessage failed", {
        updateId,
        chatId: chatIdNum,
        err: e instanceof Error ? e.message : String(e),
      });
    }

    res.status(200).json({ ok: true });
  }
);
