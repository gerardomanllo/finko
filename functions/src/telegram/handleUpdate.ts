import type { Firestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

import { commitRecurringFromLedgerTransaction } from "../recurringFromLedgerTx";
import { classifyTelegramUpdate } from "./classifyUpdate";
import { getUidForTelegramChat } from "./chatBindings";
import { consumeLinkTokenAndBindChat } from "./linkTokens";
import {
  createStandardLedgerTransaction,
  createTransferLegPairAdmin,
  loadAccountsForBot,
  loadCategoriesForBot,
  loadMainCurrency,
  loadTelegramBotPreferences,
  userTodayYmd,
} from "./ledgerToolkit";
import {
  parseReceiptCaptionWithOptionalGemini,
  parseReceiptImageWithOptionalGemini,
  parseTransactionLineWithOptionalGemini,
  parseVoiceBytesWithOptionalGemini,
} from "./geminiNlu";
import { t, type MessageKey } from "./i18n";
import { tryConsumeTelegramUpdate } from "./processedUpdates";
import { recurringScheduleDefaults } from "./recurringSchedule";
import {
  deleteTelegramBotSession,
  loadTelegramBotSession,
  resolveBotLocaleFromTelegram,
  upsertTelegramBotSession,
  type BotLocale,
} from "./sessions";
import { looksLikeSmallTalk } from "./smallTalk";
import type { TelegramMessage, TelegramUpdate } from "./types";
import {
  telegramAnswerCallbackQuery,
  telegramSendMessage,
  telegramEditMessageText,
} from "./telegramApi";
import { telegramDownloadFileBytes, telegramGetFilePath } from "./telegramFiles";

export type TelegramHandleDeps = {
  db: Firestore;
  fetchTelegram: typeof fetch;
  botToken: string;
  geminiApiKey?: string;
};

type Draft = Record<string, unknown>;

type ParsedCb =
  | { t: "confirm" }
  | { t: "cancel" }
  | { t: "pick_acc"; idx: number }
  | { t: "pick_cat"; idx: number }
  | { t: "rec_yes" }
  | { t: "rec_no" }
  | { t: "rec_cad"; cadence: "monthly" | "twiceMonthly" | "biweekly" | "weekly" }
  | { t: "tf"; idx: number }
  | { t: "tt"; idx: number };

export function parseTelegramCallbackData(data: string): ParsedCb | null {
  if (data === "cf") return { t: "confirm" };
  if (data === "cx") return { t: "cancel" };
  if (data === "ry") return { t: "rec_yes" };
  if (data === "rn") return { t: "rec_no" };
  if (data === "rm") return { t: "rec_cad", cadence: "monthly" };
  if (data === "rt") return { t: "rec_cad", cadence: "twiceMonthly" };
  if (data === "rb") return { t: "rec_cad", cadence: "biweekly" };
  if (data === "rw") return { t: "rec_cad", cadence: "weekly" };
  let m = /^pa:(\d+)$/.exec(data);
  if (m) return { t: "pick_acc", idx: Number(m[1]) };
  m = /^pc:(\d+)$/.exec(data);
  if (m) return { t: "pick_cat", idx: Number(m[1]) };
  m = /^tf:(\d+)$/.exec(data);
  if (m) return { t: "tf", idx: Number(m[1]) };
  m = /^tt:(\d+)$/.exec(data);
  if (m) return { t: "tt", idx: Number(m[1]) };
  return null;
}

function pickLocale(msg: TelegramMessage | undefined, override?: string): BotLocale {
  const o = override?.trim().toLowerCase();
  if (o === "es" || o === "en") return o;
  return resolveBotLocaleFromTelegram(msg);
}

function fmtAmount(minor: number, currency: string): string {
  return `${(minor / 100).toFixed(2)} ${currency}`;
}

function kb(rows: { text: string; callback_data: string }[][]): {
  reply_markup: { inline_keyboard: typeof rows };
} {
  return { reply_markup: { inline_keyboard: rows } };
}

async function sendReject(
  deps: TelegramHandleDeps,
  chatId: number,
  locale: BotLocale,
  key: MessageKey
): Promise<void> {
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatId, t(locale, key));
}

export async function handleTelegramUpdate(update: TelegramUpdate, deps: TelegramHandleDeps): Promise<void> {
  const updateId = update.update_id;
  if (typeof updateId !== "number") {
    return;
  }

  const fresh = await tryConsumeTelegramUpdate(deps.db, updateId);
  if (!fresh) {
    logger.info("telegramWebhook: duplicate update_id (no-op)", { updateId });
    return;
  }

  const classified = classifyTelegramUpdate(update);

  if (classified.outcome === "silent_ignore") {
    logger.info("telegramWebhook: silent_ignore", { updateId, debug: classified.debug });
    return;
  }

  if (classified.outcome === "graceful_reject") {
    const loc = classified.languageCode?.toLowerCase().startsWith("es") ? "es" : "en";
    const key: MessageKey =
      classified.reason === "unsupported_media"
        ? "unsupported_media"
        : classified.reason === "message_too_long"
          ? "message_too_long"
          : classified.reason === "emoji_only"
            ? "emoji_only"
            : "empty_message";
    if (classified.chatId !== undefined) {
      await sendReject(deps, classified.chatId, loc, key);
    }
    logger.warn("telegramWebhook: graceful_reject", {
      updateId,
      reason: classified.reason,
      chatId: classified.chatId,
    });
    return;
  }

  try {
    if (classified.outcome === "link_token") {
      await handleLinkToken(classified.chatId, classified.token, classified.message, deps);
      return;
    }
    if (classified.outcome === "plain_start") {
      const locale = pickLocale(classified.message);
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, classified.chatId, t(locale, "plain_start_hint"));
      return;
    }

    const chatIdStr = String(classified.chatId);
    const uid = await getUidForTelegramChat(deps.db, chatIdStr);
    if (!uid) {
      const loc = pickLocale(
        classified.outcome === "callback_query" ? classified.cq.message : classified.message
      );
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, classified.chatId, t(loc, "not_linked"));
      return;
    }

    const prefs = await loadTelegramBotPreferences(deps.db, uid);
    const locale = pickLocale(
      classified.outcome === "callback_query" ? classified.cq.message : classified.message,
      prefs.localeOverride
    );

    if (classified.outcome === "callback_query") {
      await handleCallback(uid, chatIdStr, classified.chatId, locale, classified.cq, deps);
      return;
    }

    if (classified.outcome === "photo") {
      await handlePhoto(uid, chatIdStr, classified.chatId, locale, classified.message, deps);
      return;
    }

    if (classified.outcome === "voice") {
      await handleVoice(uid, chatIdStr, classified.chatId, locale, classified.message, deps);
      return;
    }

    if (classified.outcome === "dialog_text") {
      await handleDialogText(
        uid,
        chatIdStr,
        classified.chatId,
        locale,
        classified.text,
        classified.message,
        deps
      );
    }
  } catch (e) {
    logger.error("telegramWebhook: handleTelegramUpdate failed", {
      updateId,
      err: e instanceof Error ? e.message : String(e),
    });
    const chatId = classified.chatId;
    const loc =
      classified.outcome === "callback_query"
        ? pickLocale(classified.cq.message)
        : pickLocale(classified.message);
    try {
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatId, t(loc, "generic_error"));
    } catch (sendErr) {
      logger.warn("telegramWebhook: generic_error send failed", {
        updateId,
        err: sendErr instanceof Error ? sendErr.message : String(sendErr),
      });
    }
  }
}

async function handleLinkToken(
  chatIdNum: number,
  token: string,
  message: TelegramMessage | undefined,
  deps: TelegramHandleDeps
): Promise<void> {
  const locale = pickLocale(message);
  const tgUser = message?.from?.username ?? message?.chat?.username;
  const usernameNorm = typeof tgUser === "string" ? tgUser.toLowerCase() : "";
  const bound = await consumeLinkTokenAndBindChat(deps.db, token, String(chatIdNum), usernameNorm);
  if (!bound.ok) {
    logger.warn("telegramWebhook: bind failed", { chatId: chatIdNum, reason: bound.reason });
    const key: MessageKey =
      bound.reason === "expired"
        ? "link_token_expired"
        : bound.reason === "used_other"
          ? "link_token_used_other"
          : "link_token_invalid";
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, key));
    return;
  }
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "link_connected"));
}

async function handleCallback(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  cq: NonNullable<TelegramUpdate["callback_query"]>,
  deps: TelegramHandleDeps
): Promise<void> {
  const cqId = typeof cq.id === "string" ? cq.id : "";
  const dataRaw = typeof cq.data === "string" ? cq.data : "";
  const parsed = parseTelegramCallbackData(dataRaw);
  const msg = cq.message;
  const messageId = typeof msg?.message_id === "number" ? msg.message_id : 0;

  if (!parsed || cqId.length === 0) {
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
      text: t(locale, "callback_invalid"),
      show_alert: false,
    });
    return;
  }

  const session = await loadTelegramBotSession(deps.db, chatIdStr);
  if (!session || session.uid !== uid) {
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
      text: t(locale, "session_expired"),
    });
    await deleteTelegramBotSession(deps.db, chatIdStr);
    return;
  }

  const draft = { ...(session.draft as Draft) };
  const accounts = (draft._accounts as { id: string; name: string; currency: string }[]) ?? [];
  const categories = (draft._categories as { id: string; name: string; kind: string }[]) ?? [];
  const mainCurrency = await loadMainCurrency(deps.db, uid);

  if (parsed.t === "cancel") {
    await deleteTelegramBotSession(deps.db, chatIdStr);
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "cancelled"));
    return;
  }

  if (parsed.t === "pick_cat") {
    const filtered = categories.filter((c) => c.kind === (draft.direction === "in" ? "income" : "expense"));
    const cat = filtered[parsed.idx];
    if (!cat) {
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
        text: t(locale, "callback_invalid"),
      });
      return;
    }
    draft.categoryId = cat.id;
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    await advanceAfterCategory(uid, chatIdStr, chatIdNum, locale, draft, accounts, categories, mainCurrency, deps, messageId);
    return;
  }

  if (parsed.t === "pick_acc") {
    const acc = accounts[parsed.idx];
    if (!acc) {
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
        text: t(locale, "callback_invalid"),
      });
      return;
    }
    draft.accountId = acc.id;
    draft.currency = acc.currency;
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    await showConfirm(uid, chatIdStr, chatIdNum, locale, draft, accounts, categories, mainCurrency, deps, messageId);
    return;
  }

  if (parsed.t === "confirm") {
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    await postStandardTx(uid, chatIdStr, chatIdNum, locale, draft, mainCurrency, deps, messageId);
    return;
  }

  if (parsed.t === "rec_no") {
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    await deleteTelegramBotSession(deps.db, chatIdStr);
    if (messageId > 0) {
      await telegramEditMessageText(
        deps.fetchTelegram,
        deps.botToken,
        chatIdNum,
        messageId,
        t(locale, "cancelled")
      );
    }
    return;
  }

  if (parsed.t === "rec_yes") {
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    const rows = [
      [
        { text: "Monthly", callback_data: "rm" },
        { text: "2×/mo", callback_data: "rt" },
      ],
      [
        { text: "Biweekly", callback_data: "rb" },
        { text: "Weekly", callback_data: "rw" },
      ],
      [{ text: "✗", callback_data: "rn" }],
    ];
    draft.step = "pick_recurring_cadence";
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale,
      intent: session.intent,
      step: "pick_recurring_cadence",
      draft,
    });
    if (messageId > 0) {
      await telegramEditMessageText(
        deps.fetchTelegram,
        deps.botToken,
        chatIdNum,
        messageId,
        t(locale, "pick_recurring_cadence"),
        kb(rows)
      );
    }
    return;
  }

  if (parsed.t === "rec_cad") {
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    const txId = typeof draft.pendingTxId === "string" ? draft.pendingTxId : "";
    if (!txId) {
      await deleteTelegramBotSession(deps.db, chatIdStr);
      return;
    }
    const tzSnap = await deps.db.doc(`users/${uid}`).get();
    const tz =
      tzSnap.exists && typeof tzSnap.data()?.timezone === "string"
        ? tzSnap.data()!.timezone.trim()
        : "";
    const txSnap = await deps.db.doc(`users/${uid}/transactions/${txId}`).get();
    const txDate =
      txSnap.exists && typeof txSnap.data()?.transactionDate === "string"
        ? txSnap.data()!.transactionDate
        : "";
    const sched = recurringScheduleDefaults(txDate, parsed.cadence);
    try {
      await commitRecurringFromLedgerTransaction(deps.db, uid, {
        transactionId: txId,
        cadence: parsed.cadence,
        daysOfMonth: sched.daysOfMonth,
        weekday: sched.weekday,
        timezone: tz.length > 0 ? tz : undefined,
      });
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "posted_recurring"));
    } catch (e) {
      logger.error("telegram recurring failed", { err: String(e) });
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    }
    await deleteTelegramBotSession(deps.db, chatIdStr);
    if (messageId > 0) {
      await telegramEditMessageText(
        deps.fetchTelegram,
        deps.botToken,
        chatIdNum,
        messageId,
        t(locale, "posted_recurring")
      );
    }
    return;
  }

  if (parsed.t === "tf") {
    const acc = accounts[parsed.idx];
    if (!acc) {
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
        text: t(locale, "callback_invalid"),
      });
      return;
    }
    draft.transferFromId = acc.id;
    draft.transferFromCurrency = acc.currency;
    draft.step = "transfer_to";
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale,
      intent: "transfer",
      step: "transfer_to",
      draft,
    });
    await promptTransferTo(chatIdNum, locale, accounts, deps);
    return;
  }

  if (parsed.t === "tt") {
    const acc = accounts[parsed.idx];
    const fromId = typeof draft.transferFromId === "string" ? draft.transferFromId : "";
    if (!acc || !fromId || acc.id === fromId) {
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
        text: t(locale, "transfer_same_account"),
      });
      return;
    }
    draft.transferToId = acc.id;
    draft.transferToCurrency = acc.currency;
    draft.step = "transfer_amount";
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale,
      intent: "transfer",
      step: "transfer_amount",
      draft,
    });
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "transfer_enter_amount"));
    return;
  }
}

async function promptTransferTo(
  chatIdNum: number,
  locale: BotLocale,
  accounts: { id: string; name: string; currency: string }[],
  deps: TelegramHandleDeps
): Promise<void> {
  const rows: { text: string; callback_data: string }[][] = [];
  let row: { text: string; callback_data: string }[] = [];
  accounts.forEach((a, i) => {
    row.push({
      text: a.name.slice(0, 24),
      callback_data: `tt:${i}`,
    });
    if (row.length === 2) {
      rows.push(row);
      row = [];
    }
  });
  if (row.length) rows.push(row);
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "pick_transfer_to"), kb(rows));
}

async function advanceAfterCategory(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  draft: Draft,
  accounts: { id: string; name: string; currency: string }[],
  categories: { id: string; name: string; kind: string }[],
  mainCurrency: string,
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  const catId = typeof draft.categoryId === "string" ? draft.categoryId : "";
  const cat = categories.find((c) => c.id === catId);
  const prefs = await loadTelegramBotPreferences(deps.db, uid);
  const defaultAcc =
    typeof prefs.defaultAccountId === "string" ? prefs.defaultAccountId.trim() : "";
  const accHit = accounts.find((a) => a.id === defaultAcc);
  if (accHit && cat) {
    draft.accountId = accHit.id;
    draft.currency = accHit.currency;
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale,
      intent: draft.intent === "income" ? "income" : "expense",
      step: "confirm",
      draft,
    });
    await showConfirm(uid, chatIdStr, chatIdNum, locale, draft, accounts, categories, mainCurrency, deps, messageId);
    return;
  }
  await promptPickAccount(uid, chatIdStr, chatIdNum, locale, draft, accounts, deps, messageId);
}

async function promptPickAccount(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  draft: Draft,
  accounts: { id: string; name: string; currency: string }[],
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  draft.step = "pick_account";
  await upsertTelegramBotSession(deps.db, chatIdStr, {
    uid,
    locale,
    intent: draft.intent === "income" ? "income" : "expense",
    step: "pick_account",
    draft,
  });
  const rows: { text: string; callback_data: string }[][] = [];
  let row: { text: string; callback_data: string }[] = [];
  accounts.forEach((a, i) => {
    row.push({ text: `${a.name.slice(0, 20)} (${a.currency})`, callback_data: `pa:${i}` });
    if (row.length === 2) {
      rows.push(row);
      row = [];
    }
  });
  if (row.length) rows.push(row);
  rows.push([{ text: "✗", callback_data: "cx" }]);
  const text = t(locale, "pick_account");
  if (messageId > 0) {
    await telegramEditMessageText(deps.fetchTelegram, deps.botToken, chatIdNum, messageId, text, kb(rows));
  } else {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, text, kb(rows));
  }
}

async function showConfirm(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  draft: Draft,
  accounts: { id: string; name: string; currency: string }[],
  categories: { id: string; name: string; kind: string }[],
  mainCurrency: string,
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  draft.step = "confirm";
  await upsertTelegramBotSession(deps.db, chatIdStr, {
    uid,
    locale,
    intent: draft.intent === "income" ? "income" : "expense",
    step: "confirm",
    draft,
  });
  const amountMinor = typeof draft.amountMinor === "number" ? draft.amountMinor : 0;
  const memo = typeof draft.memo === "string" ? draft.memo : "";
  const direction = draft.direction === "in" ? "in" : "out";
  const accId = typeof draft.accountId === "string" ? draft.accountId : "";
  const catId = typeof draft.categoryId === "string" ? draft.categoryId : "";
  const cur = typeof draft.currency === "string" ? draft.currency : mainCurrency;
  const accName = accounts.find((a) => a.id === accId)?.name ?? accId;
  const catName = categories.find((c) => c.id === catId)?.name ?? catId;
  const body = t(locale, "confirm_transaction", {
    direction: direction === "in" ? "IN" : "OUT",
    amount: fmtAmount(amountMinor, cur),
    memo,
    account: accName,
    category: catName,
  });
  const rows = [[{ text: "✓", callback_data: "cf" }, { text: "✗", callback_data: "cx" }]];
  if (messageId > 0) {
    await telegramEditMessageText(deps.fetchTelegram, deps.botToken, chatIdNum, messageId, body, kb(rows));
  } else {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, body, kb(rows));
  }
}

async function postStandardTx(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  draft: Draft,
  mainCurrency: string,
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  const ymd = await userTodayYmd(deps.db, uid);
  const amountMinor = typeof draft.amountMinor === "number" ? draft.amountMinor : 0;
  const memo = typeof draft.memo === "string" ? draft.memo : "";
  const direction = draft.direction === "in" ? "in" : "out";
  const accId = typeof draft.accountId === "string" ? draft.accountId : "";
  const catId = typeof draft.categoryId === "string" ? draft.categoryId : "";
  const cur = (typeof draft.currency === "string" ? draft.currency : mainCurrency).toUpperCase();
  if (!accId || !catId || amountMinor <= 0) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    await deleteTelegramBotSession(deps.db, chatIdStr);
    return;
  }
  const txId = await createStandardLedgerTransaction(deps.db, uid, {
    transactionDate: ymd,
    amountMinor,
    direction,
    currency: cur,
    accountId: accId,
    categoryId: catId,
    memo,
  });
  const postedKey: MessageKey = direction === "in" ? "posted_income" : "posted_expense";
  const msgPosted = t(locale, postedKey, { memo, amount: fmtAmount(amountMinor, cur) });
  draft.pendingTxId = txId;
  draft.step = "recurring_ask";
  await upsertTelegramBotSession(deps.db, chatIdStr, {
    uid,
    locale,
    intent: draft.intent === "income" ? "income" : "expense",
    step: "recurring_ask",
    draft,
  });
  const rows = [
    [
      { text: "✓", callback_data: "ry" },
      { text: "✗", callback_data: "rn" },
    ],
  ];
  const prompt = `${msgPosted}\n\n${t(locale, "make_recurring_prompt")}`;
  if (messageId > 0) {
    await telegramEditMessageText(deps.fetchTelegram, deps.botToken, chatIdNum, messageId, prompt, kb(rows));
  } else {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, prompt, kb(rows));
  }
}

async function handlePhoto(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  message: TelegramMessage,
  deps: TelegramHandleDeps
): Promise<void> {
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "processing_photo"));
  const photos = message.photo ?? [];
  if (photos.length === 0) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    return;
  }
  const best = photos.reduce((a, b) => ((b.height ?? 0) > (a.height ?? 0) ? b : a), photos[0]);
  const fileId = typeof best?.file_id === "string" ? best.file_id : "";
  const caption = typeof message.caption === "string" ? message.caption : "";
  const accounts = await loadAccountsForBot(deps.db, uid);
  const categories = await loadCategoriesForBot(deps.db, uid);
  const mainCurrency = await loadMainCurrency(deps.db, uid);
  let parsed: Awaited<ReturnType<typeof parseReceiptImageWithOptionalGemini>> = null;
  if (caption.trim().length > 0) {
    parsed = await parseReceiptCaptionWithOptionalGemini(
      deps.geminiApiKey,
      mainCurrency,
      caption,
      categories
    );
  }
  if (fileId && deps.botToken) {
    const path = await telegramGetFilePath(deps.fetchTelegram, deps.botToken, fileId);
    if (path) {
      const bytes = await telegramDownloadFileBytes(deps.fetchTelegram, deps.botToken, path);
      if (bytes && bytes.length > 0) {
        const mime = path.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";
        parsed = await parseReceiptImageWithOptionalGemini(
          deps.geminiApiKey,
          mainCurrency,
          bytes,
          mime,
          caption,
          categories
        );
      }
    }
  }
  if (!parsed || parsed.amountMinor <= 0) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    return;
  }
  await beginSpendFlow(uid, chatIdStr, chatIdNum, locale, parsed, accounts, categories, mainCurrency, deps, 0);
}

async function handleVoice(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  message: TelegramMessage,
  deps: TelegramHandleDeps
): Promise<void> {
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "processing_voice"));
  const fileId = typeof message.voice?.file_id === "string" ? message.voice.file_id : "";
  const accounts = await loadAccountsForBot(deps.db, uid);
  const categories = await loadCategoriesForBot(deps.db, uid);
  const mainCurrency = await loadMainCurrency(deps.db, uid);
  let parsed = null as Awaited<ReturnType<typeof parseVoiceBytesWithOptionalGemini>>;
  if (fileId) {
    const path = await telegramGetFilePath(deps.fetchTelegram, deps.botToken, fileId);
    if (path) {
      const bytes = await telegramDownloadFileBytes(deps.fetchTelegram, deps.botToken, path);
      if (bytes && bytes.length > 0) {
        parsed = await parseVoiceBytesWithOptionalGemini(
          deps.geminiApiKey,
          mainCurrency,
          bytes,
          "audio/ogg",
          categories
        );
      }
    }
  }
  if (!parsed || parsed.amountMinor <= 0) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    return;
  }
  await beginSpendFlow(uid, chatIdStr, chatIdNum, locale, parsed, accounts, categories, mainCurrency, deps, 0);
}

async function beginSpendFlow(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  parsed: { amountMinor: number; memo: string; direction: "in" | "out"; categoryId?: string },
  accounts: { id: string; name: string; currency: string }[],
  categories: { id: string; name: string; kind: string }[],
  mainCurrency: string,
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  const prefs = await loadTelegramBotPreferences(deps.db, uid);
  const draft: Draft = {
    amountMinor: parsed.amountMinor,
    memo: parsed.memo,
    direction: parsed.direction,
    intent: parsed.direction === "in" ? "income" : "expense",
    categoryId: parsed.categoryId,
    _accounts: accounts,
    _categories: categories,
  };
  const kind = parsed.direction === "in" ? "income" : "expense";
  let catId = parsed.categoryId;
  if (!catId || !categories.find((c) => c.id === catId && c.kind === kind)) {
    const defaultCat =
      kind === "income"
        ? prefs.defaultIncomeCategoryId?.trim()
        : prefs.defaultExpenseCategoryId?.trim();
    if (defaultCat && categories.find((c) => c.id === defaultCat && c.kind === kind)) {
      catId = defaultCat;
      draft.categoryId = defaultCat;
    }
  }
  if (!catId || !categories.find((c) => c.id === catId && c.kind === kind)) {
    await promptPickCategory(uid, chatIdStr, chatIdNum, locale, draft, categories, deps, messageId);
    return;
  }
  draft.categoryId = catId;
  await advanceAfterCategory(uid, chatIdStr, chatIdNum, locale, draft, accounts, categories, mainCurrency, deps, messageId);
}

async function promptPickCategory(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  draft: Draft,
  categories: { id: string; name: string; kind: string }[],
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  const kind = draft.direction === "in" ? "income" : "expense";
  const filtered = categories.filter((c) => c.kind === kind);
  const rows: { text: string; callback_data: string }[][] = [];
  let row: { text: string; callback_data: string }[] = [];
  filtered.forEach((c, i) => {
    row.push({ text: c.name.slice(0, 28), callback_data: `pc:${i}` });
    if (row.length === 2) {
      rows.push(row);
      row = [];
    }
  });
  if (row.length) rows.push(row);
  rows.push([{ text: "✗", callback_data: "cx" }]);
  draft.step = "pick_category";
  await upsertTelegramBotSession(deps.db, chatIdStr, {
    uid,
    locale,
    intent: draft.intent === "income" ? "income" : "expense",
    step: "pick_category",
    draft,
  });
  const textBody = t(locale, "pick_category");
  if (messageId > 0) {
    await telegramEditMessageText(deps.fetchTelegram, deps.botToken, chatIdNum, messageId, textBody, kb(rows));
  } else {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, textBody, kb(rows));
  }
}

async function handleDialogText(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  text: string,
  message: TelegramMessage,
  deps: TelegramHandleDeps
): Promise<void> {
  void message;
  const accounts = await loadAccountsForBot(deps.db, uid);
  const categories = await loadCategoriesForBot(deps.db, uid);
  const mainCurrency = await loadMainCurrency(deps.db, uid);
  const session = await loadTelegramBotSession(deps.db, chatIdStr);
  const norm = text.trim().toLowerCase();

  if (norm === "/help") {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "help"));
    return;
  }
  if (norm === "/cancel") {
    await deleteTelegramBotSession(deps.db, chatIdStr);
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "cancelled"));
    return;
  }

  if (norm === "/transfer") {
    const draft: Draft = {
      step: "transfer_from",
      _accounts: accounts,
      _categories: categories,
    };
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale,
      intent: "transfer",
      step: "transfer_from",
      draft,
    });
    const rows: { text: string; callback_data: string }[][] = [];
    let row: { text: string; callback_data: string }[] = [];
    accounts.forEach((a, i) => {
      row.push({ text: a.name.slice(0, 24), callback_data: `tf:${i}` });
      if (row.length === 2) {
        rows.push(row);
        row = [];
      }
    });
    if (row.length) rows.push(row);
    rows.push([{ text: "✗", callback_data: "cx" }]);
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "pick_transfer_from"), kb(rows));
    return;
  }

  if (session?.intent === "transfer" && session.step === "transfer_amount") {
    const draft = { ...(session.draft as Draft) };
    const parsed = await parseTransactionLineWithOptionalGemini(
      deps.geminiApiKey,
      mainCurrency,
      text,
      categories
    );
    if (!parsed || parsed.direction !== "out" || parsed.amountMinor <= 0) {
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "amount_missing"));
      return;
    }
    const fromId = typeof draft.transferFromId === "string" ? draft.transferFromId : "";
    const toId = typeof draft.transferToId === "string" ? draft.transferToId : "";
    const fromCur = typeof draft.transferFromCurrency === "string" ? draft.transferFromCurrency : "";
    const toCur = typeof draft.transferToCurrency === "string" ? draft.transferToCurrency : "";
    if (fromCur !== toCur) {
      await telegramSendMessage(
        deps.fetchTelegram,
        deps.botToken,
        chatIdNum,
        "Cross-currency transfers: please use the Finko app."
      );
      await deleteTelegramBotSession(deps.db, chatIdStr);
      return;
    }
    const ymd = await userTodayYmd(deps.db, uid);
    await createTransferLegPairAdmin(deps.db, uid, {
      transactionDate: ymd,
      fromAccountId: fromId,
      fromCurrency: fromCur,
      fromAmountMinor: parsed.amountMinor,
      toAccountId: toId,
      toCurrency: toCur,
      toAmountMinor: parsed.amountMinor,
      memo: parsed.memo,
    });
    await telegramSendMessage(
      deps.fetchTelegram,
      deps.botToken,
      chatIdNum,
      t(locale, "posted_transfer", { amount: fmtAmount(parsed.amountMinor, fromCur) })
    );
    await deleteTelegramBotSession(deps.db, chatIdStr);
    return;
  }

  const parsed = await parseTransactionLineWithOptionalGemini(
    deps.geminiApiKey,
    mainCurrency,
    text,
    categories
  );
  if (!parsed || parsed.amountMinor <= 0) {
    const key: MessageKey = looksLikeSmallTalk(norm) ? "small_talk_hint" : "amount_missing";
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, key));
    return;
  }

  await beginSpendFlow(uid, chatIdStr, chatIdNum, locale, parsed, accounts, categories, mainCurrency, deps, 0);
}
