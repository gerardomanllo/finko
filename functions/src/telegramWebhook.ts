import { getFirestore } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { handleTelegramUpdate } from "./telegram/handleUpdate";
import type { TelegramUpdate } from "./telegram/types";
import {
  geminiApiKey,
  telegramBotToken,
  telegramWebhookDevBypass,
  telegramWebhookSecret,
} from "./telegram/secrets";

export const telegramWebhook = onRequest(
  {
    region: "us-central1",
    secrets: [telegramBotToken, telegramWebhookSecret, geminiApiKey],
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

    const botTok = telegramBotToken.value();
    const geminiKey = geminiApiKey.value().trim();

    try {
      await handleTelegramUpdate(update, {
        db: getFirestore(),
        fetchTelegram: fetch,
        botToken: botTok,
        geminiApiKey: geminiKey.length > 0 ? geminiKey : undefined,
      });
    } catch (e) {
      logger.error("telegramWebhook: handler threw", {
        err: e instanceof Error ? e.message : String(e),
      });
    }

    res.status(200).json({ ok: true });
  }
);
