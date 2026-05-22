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
  analyzeFirstMessageWithGemini,
  applyPreferenceDefaults,
  continueDialogWithGemini,
  detectMessageLanguageWithGemini,
  EMPTY_TRANSACTION_SNAPSHOT,
  snapshotFromDraftRecord,
  snapshotFromLegacySpendDraft,
  snapshotFromTransferWizardDraft,
  validateTransactionSnapshot,
  type GeminiTransactionSnapshot,
} from "./geminiOrchestrator";
import {
  type NluParseResult,
  parseReceiptCaptionWithOptionalGemini,
  parseReceiptImageWithOptionalGemini,
  parseTransactionLineWithOptionalGemini,
  parseVoiceBytesWithOptionalGemini,
} from "./geminiNlu";
import { t, type MessageKey } from "./i18n";
import { tryConsumeTelegramUpdate } from "./processedUpdates";
import { recurringScheduleDefaults } from "./recurringSchedule";
import { pickBotLocale } from "./localeInference";
import {
  deleteTelegramBotSession,
  loadTelegramBotSession,
  upsertTelegramBotSession,
  type BotIntent,
  type BotLocale,
} from "./sessions";
import { localeForSmallTalkReply, looksLikeSmallTalk } from "./smallTalk";
import { parseAmountMinorFromFollowUp, suggestsConversationalParse, truncateForTelegram } from "./parseTxText";
import type { TelegramMessage, TelegramUpdate } from "./types";
import {
  telegramAnswerCallbackQuery,
  telegramSendMessage,
  telegramEditMessageTextOrSend,
} from "./telegramApi";
import { telegramDownloadFileBytes, telegramGetFilePath } from "./telegramFiles";
import { formatLedgerAmountMinor } from "./telegramAmountFormat";
import {
  resolveIdAtIndex,
  setPickAccountOrder,
  setPickCategoryOrder,
  setTransferFromOrder,
  setTransferToOrder,
} from "./telegramPickerOrder";

export type TelegramHandleDeps = {
  db: Firestore;
  fetchTelegram: typeof fetch;
  botToken: string;
  geminiApiKey?: string;
};

type Draft = Record<string, unknown>;

async function logGeminiNullThenGenericError(
  deps: TelegramHandleDeps,
  chatIdNum: number,
  loc: BotLocale,
  chatIdStr: string,
  reason: string
): Promise<void> {
  logger.warn("telegramWebhook: gemini_turn_null", { chatIdStr, reason });
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(loc, "generic_error"));
}

export type ParsedCb =
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

function pickListAmountHint(locale: BotLocale, draft: Draft, mainCurrency: string): string {
  const minor = typeof draft.amountMinor === "number" ? draft.amountMinor : 0;
  if (!Number.isFinite(minor) || minor <= 0) return "";
  const curRaw = typeof draft.currency === "string" ? draft.currency.trim() : "";
  const cur = (curRaw.length > 0 ? curRaw : mainCurrency).toUpperCase();
  const label = locale === "es" ? "Monto" : "Amount";
  return `${label}: ${formatLedgerAmountMinor(Math.round(minor), cur)}\n\n`;
}

function buildConfirmDraftFromSnapshot(
  snap: GeminiTransactionSnapshot,
  base: Draft,
  accounts: { id: string; name: string; currency: string }[],
  categories: { id: string; name: string; kind: string }[],
  mainCurrency: string
): Draft {
  const draft: Draft = {
    ...base,
    _accounts: accounts,
    _categories: categories,
  };
  if (snap.txKind === "transfer") {
    const fromA = accounts.find((a) => a.id === snap.transferFromId);
    const toA = accounts.find((a) => a.id === snap.transferToId);
    if (!fromA || !toA || snap.amountMinor == null) {
      return draft;
    }
    draft.txKind = "transfer";
    draft.transferFromId = snap.transferFromId;
    draft.transferToId = snap.transferToId;
    draft.transferFromCurrency = fromA.currency;
    draft.transferToCurrency = toA.currency;
    draft.amountMinor = snap.amountMinor;
    draft.amountMinorTo = snap.amountMinorTo;
    const memo = (snap.memo ?? "").trim();
    draft.memo = memo.length > 0 ? memo.slice(0, 200) : "";
    draft.direction = "out";
    draft.intent = "transfer";
    return draft;
  }
  const acc = accounts.find((a) => a.id === snap.accountId);
  if (!acc || snap.amountMinor == null || !snap.memo || !snap.categoryId || !snap.accountId) {
    return draft;
  }
  draft.txKind = "standard";
  draft.amountMinor = snap.amountMinor;
  draft.memo = snap.memo.trim().slice(0, 200);
  draft.direction = snap.direction === "in" ? "in" : "out";
  draft.categoryId = snap.categoryId;
  draft.accountId = snap.accountId;
  draft.currency = acc.currency;
  draft.intent = snap.direction === "in" ? "income" : "expense";
  return draft;
}

/** Mirrors txKind inference in `validateTransactionSnapshot` — keep in sync when that logic changes. */
function inferSpendTxKindForPickerRouting(s: GeminiTransactionSnapshot): "standard" | "transfer" | null {
  let kind = s.txKind;
  if (kind == null && s.transferFromId && s.transferToId) {
    kind = "transfer";
  }
  if (kind == null && s.direction && (s.categoryId != null || (s.memo ?? "").trim().length > 0)) {
    kind = "standard";
  }
  if (kind === "transfer") return "transfer";
  if (kind === "standard") return "standard";
  return null;
}

function isRecoverableStandardSpendForPickers(validated: GeminiTransactionSnapshot): boolean {
  const dir = validated.direction === "in" || validated.direction === "out" ? validated.direction : null;
  const amt = validated.amountMinor;
  const memo = (validated.memo ?? "").trim();
  if (dir == null || amt == null || amt <= 0 || memo.length === 0) return false;

  if (inferSpendTxKindForPickerRouting(validated) !== "standard") return false;

  const fromLeg = validated.transferFromId != null && String(validated.transferFromId).length > 0;
  const toLeg = validated.transferToId != null && String(validated.transferToId).length > 0;
  if (fromLeg !== toLeg) return false;

  return true;
}

async function tryFinalizeSpendViaPickersFromPartialSnap(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  loc: BotLocale,
  validated: GeminiTransactionSnapshot,
  prevDraft: Draft,
  accounts: { id: string; name: string; currency: string }[],
  categories: { id: string; name: string; kind: string }[],
  mainCurrency: string,
  deps: TelegramHandleDeps
): Promise<boolean> {
  if (!isRecoverableStandardSpendForPickers(validated)) return false;

  const direction = validated.direction === "in" ? "in" : "out";
  const ledgerKind = direction === "in" ? "income" : "expense";

  const validatedCat =
    validated.categoryId && categories.some((c) => c.id === validated.categoryId && c.kind === ledgerKind)
      ? validated.categoryId
      : undefined;
  const accRaw = validated.accountId;
  const validatedAcc =
    typeof accRaw === "string" &&
    accRaw.trim().length > 0 &&
    accounts.some((a) => a.id === accRaw.trim())
      ? accRaw.trim()
      : undefined;

  const draft: Draft = {
    ...prevDraft,
    txKind: "standard",
    direction,
    intent: ledgerKind === "income" ? "income" : "expense",
    amountMinor: validated.amountMinor,
    memo: (validated.memo ?? "").trim().slice(0, 200),
    _accounts: accounts,
    _categories: categories,
  };
  delete draft.categoryId;
  delete draft.accountId;
  delete draft.currency;
  if (validatedCat !== undefined) draft.categoryId = validatedCat;
  if (validatedAcc !== undefined) draft.accountId = validatedAcc;

  await finalizeSpendCategoryResolution(
    uid,
    chatIdStr,
    chatIdNum,
    loc,
    draft,
    accounts,
    categories,
    mainCurrency,
    deps,
    0
  );
  return true;
}

async function finalizeTelegramGeminiSnapshotFromModelSnap(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  loc: BotLocale,
  prefs: Awaited<ReturnType<typeof loadTelegramBotPreferences>>,
  rawSnap: GeminiTransactionSnapshot,
  prevDraft: Draft,
  accounts: { id: string; name: string; currency: string }[],
  categories: { id: string; name: string; kind: string }[],
  mainCurrency: string,
  deps: TelegramHandleDeps
): Promise<void> {
  let snap = applyPreferenceDefaults(rawSnap, prefs, categories, accounts);
  const { ok, snap: validated } = validateTransactionSnapshot(snap, categories, accounts);
  if (ok) {
    const draft = buildConfirmDraftFromSnapshot(
      validated,
      { ...prevDraft },
      accounts,
      categories,
      mainCurrency
    );
    const intentForSession: BotIntent =
      validated.txKind === "transfer"
        ? "transfer"
        : validated.direction === "in"
          ? "income"
          : "expense";
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale: loc,
      intent: intentForSession,
      step: "confirm",
      draft,
    });
    await showConfirm(uid, chatIdStr, chatIdNum, loc, draft, accounts, categories, mainCurrency, deps, 0);
    return;
  }
  if (
    await tryFinalizeSpendViaPickersFromPartialSnap(
      uid,
      chatIdStr,
      chatIdNum,
      loc,
      validated,
      prevDraft,
      accounts,
      categories,
      mainCurrency,
      deps
    )
  ) {
    return;
  }
  const draft: Draft = {
    ...prevDraft,
    _accounts: accounts,
    _categories: categories,
    _geminiSnapshot: validated as unknown as Record<string, unknown>,
  };
  await upsertTelegramBotSession(deps.db, chatIdStr, {
    uid,
    locale: loc,
    intent: "expense",
    step: "gemini_collect",
    draft,
  });
  const msg = validated.assistantMessage.trim() || t(loc, "parse_error");
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, truncateForTelegram(msg));
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

async function detectStrictTextLocale(
  text: string,
  fallbackLocale: BotLocale,
  deps: TelegramHandleDeps,
  chatIdNum: number
): Promise<BotLocale | null> {
  const key = deps.geminiApiKey?.trim() ?? "";
  if (!key) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(fallbackLocale, "language_not_understood"));
    return null;
  }
  const detected = await detectMessageLanguageWithGemini(key, text);
  if (!detected) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(fallbackLocale, "language_not_understood"));
    return null;
  }
  return detected;
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
    const loc = pickBotLocale({
      message:
        typeof classified.languageCode === "string" && classified.languageCode.length > 0
          ? { from: { language_code: classified.languageCode } }
          : undefined,
    });
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
      const locale = pickBotLocale({ message: classified.message });
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, classified.chatId, t(locale, "plain_start_hint"));
      return;
    }

    const chatIdStr = String(classified.chatId);
    const uid = await getUidForTelegramChat(deps.db, chatIdStr);
    if (!uid) {
      const msg =
        classified.outcome === "callback_query" ? classified.cq.message : classified.message;
      const loc = pickBotLocale({ message: msg });
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, classified.chatId, t(loc, "not_linked"));
      return;
    }

    const prefs = await loadTelegramBotPreferences(deps.db, uid);

    if (classified.outcome === "callback_query") {
      const fallbackLocale = pickBotLocale({
        localeOverride: prefs.localeOverride,
        message: classified.cq.message,
      });
      await handleCallback(uid, chatIdStr, classified.chatId, fallbackLocale, classified.cq, deps);
      return;
    }

    if (classified.outcome === "photo") {
      await handlePhoto(uid, chatIdStr, classified.chatId, prefs, classified.message, deps);
      return;
    }

    if (classified.outcome === "voice") {
      await handleVoice(uid, chatIdStr, classified.chatId, prefs, classified.message, deps);
      return;
    }

    if (classified.outcome === "dialog_text") {
      await handleDialogText(
        uid,
        chatIdStr,
        classified.chatId,
        prefs,
        classified.text,
        classified.message,
        deps
      );
    }
  } catch (e) {
    logger.error("telegramWebhook: handleTelegramUpdate failed", {
      updateId,
      outcome: classified.outcome,
      err: e instanceof Error ? e.message : String(e),
      stack: e instanceof Error ? e.stack : undefined,
    });
    const chatId = classified.chatId;
    const loc =
      classified.outcome === "callback_query"
        ? pickBotLocale({ message: classified.cq.message })
        : pickBotLocale({ message: classified.message });
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
  const locale = pickBotLocale({ message });
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

export async function handleCallback(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  initialLocale: BotLocale,
  cq: NonNullable<TelegramUpdate["callback_query"]>,
  deps: TelegramHandleDeps
): Promise<void> {
  let locale = initialLocale;
  const cqIdRaw = cq.id;
  const cqId =
    cqIdRaw !== undefined && cqIdRaw !== null && String(cqIdRaw).trim().length > 0
      ? String(cqIdRaw).trim()
      : "";
  const dataRaw = typeof cq.data === "string" ? cq.data : "";
  const parsed = parseTelegramCallbackData(dataRaw);
  const msg = cq.message;
  const messageId = typeof msg?.message_id === "number" ? msg.message_id : 0;

  if (!parsed || cqId.length === 0) {
    if (cqId.length > 0) {
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
        text: t(locale, "callback_invalid"),
        show_alert: false,
      });
    }
    return;
  }

  try {
    const session = await loadTelegramBotSession(deps.db, chatIdStr);
    if (!session || session.uid !== uid) {
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
        text: t(locale, "session_expired"),
      });
      await deleteTelegramBotSession(deps.db, chatIdStr);
      return;
    }

    locale = session.locale === "es" || session.locale === "en" ? session.locale : locale;

    const draft = { ...(session.draft as Draft) };
    const accounts = (draft._accounts as { id: string; name: string; currency: string }[]) ?? [];
    const categories = (draft._categories as { id: string; name: string; kind: string }[]) ?? [];

    if (parsed.t === "cancel") {
      await deleteTelegramBotSession(deps.db, chatIdStr);
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
        text: t(locale, "callback_discarded"),
        show_alert: false,
      });
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "cancelled"));
      return;
    }

    const mainCurrency = await loadMainCurrency(deps.db, uid);

    if (parsed.t === "pick_cat") {
      if (session.step !== "pick_category") {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      const kind = draft.direction === "in" ? "income" : "expense";
      const filtered = categories.filter((c) => c.kind === kind);
      const fallbackIds = filtered.map((c) => c.id);
      const resolvedId = resolveIdAtIndex(draft._pickCategoryOrder, parsed.idx, fallbackIds);
      const cat =
        (resolvedId ? filtered.find((c) => c.id === resolvedId) : undefined) ?? filtered[parsed.idx];
      if (!cat) {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      draft.categoryId = cat.id;
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
      await advanceAfterCategory(
        uid,
        chatIdStr,
        chatIdNum,
        locale,
        draft,
        accounts,
        categories,
        mainCurrency,
        deps,
        messageId,
        cat
      );
      return;
    }

    if (parsed.t === "pick_acc") {
      if (session.step !== "pick_account") {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      const fallbackIds = accounts.map((a) => a.id);
      const resolvedId = resolveIdAtIndex(draft._pickAccountOrder, parsed.idx, fallbackIds);
      const acc =
        (resolvedId ? accounts.find((a) => a.id === resolvedId) : undefined) ?? accounts[parsed.idx];
      if (!acc) {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      draft.accountId = acc.id;
      draft.currency = acc.currency;
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
      await showConfirm(
        uid,
        chatIdStr,
        chatIdNum,
        locale,
        draft,
        accounts,
        categories,
        mainCurrency,
        deps,
        messageId
      );
      return;
    }

    if (parsed.t === "confirm") {
      if (session.step !== "confirm") {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
        text: t(locale, "callback_saved"),
        show_alert: false,
      });
      if (draft.txKind === "transfer") {
        await postTransferTx(uid, chatIdStr, chatIdNum, locale, draft, deps, messageId);
      } else {
        await postStandardTx(uid, chatIdStr, chatIdNum, locale, draft, mainCurrency, deps, messageId);
      }
      return;
    }

    if (parsed.t === "rec_no") {
      if (session.step !== "recurring_ask" && session.step !== "pick_recurring_cadence") {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
      await deleteTelegramBotSession(deps.db, chatIdStr);
      await telegramEditMessageTextOrSend(
        deps.fetchTelegram,
        deps.botToken,
        chatIdNum,
        messageId,
        t(locale, "cancelled")
      );
      return;
    }

    if (parsed.t === "rec_yes") {
      if (session.step !== "recurring_ask") {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
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
      await telegramEditMessageTextOrSend(
        deps.fetchTelegram,
        deps.botToken,
        chatIdNum,
        messageId,
        t(locale, "pick_recurring_cadence"),
        kb(rows)
      );
      return;
    }

    if (parsed.t === "rec_cad") {
      if (session.step !== "pick_recurring_cadence") {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
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
      await telegramEditMessageTextOrSend(
        deps.fetchTelegram,
        deps.botToken,
        chatIdNum,
        messageId,
        t(locale, "posted_recurring")
      );
      return;
    }

    if (parsed.t === "tf") {
      if (session.step !== "transfer_from") {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      const fromFallbackIds = accounts.map((a) => a.id);
      const fromResolved = resolveIdAtIndex(draft._transferFromOrder, parsed.idx, fromFallbackIds);
      const acc =
        (fromResolved ? accounts.find((a) => a.id === fromResolved) : undefined) ?? accounts[parsed.idx];
      if (!acc) {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      draft.transferFromId = acc.id;
      draft.transferFromCurrency = acc.currency;
      draft.step = "transfer_to";
      const toPickerAccounts = accounts.filter((a) => a.id !== acc.id);
      setTransferToOrder(draft, toPickerAccounts.map((a) => a.id));
      await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId);
      await upsertTelegramBotSession(deps.db, chatIdStr, {
        uid,
        locale,
        intent: "transfer",
        step: "transfer_to",
        draft,
      });
      await promptTransferTo(chatIdNum, locale, toPickerAccounts, deps);
      return;
    }

    if (parsed.t === "tt") {
      if (session.step !== "transfer_to") {
        await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
          text: t(locale, "callback_invalid"),
        });
        return;
      }
      const fromId = typeof draft.transferFromId === "string" ? draft.transferFromId : "";
      const toPickerAccounts = accounts.filter((a) => a.id !== fromId);
      const toFallbackIds = toPickerAccounts.map((a) => a.id);
      const toResolved = resolveIdAtIndex(draft._transferToOrder, parsed.idx, toFallbackIds);
      const acc =
        (toResolved ? accounts.find((a) => a.id === toResolved) : undefined) ??
        toPickerAccounts[parsed.idx];
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

    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId, {
      text: t(locale, "callback_invalid"),
    });
  } catch (e) {
    logger.error("telegramWebhook: handleCallback failed", {
      err: e instanceof Error ? e.message : String(e),
      uid,
      chatIdStr,
      cqId,
      dataRaw,
    });
    await telegramAnswerCallbackQuery(deps.fetchTelegram, deps.botToken, cqId).catch(() => undefined);
    throw e;
  }
}

async function promptTransferTo(
  chatIdNum: number,
  locale: BotLocale,
  pickerAccounts: { id: string; name: string; currency: string }[],
  deps: TelegramHandleDeps
): Promise<void> {
  const rows: { text: string; callback_data: string }[][] = [];
  let row: { text: string; callback_data: string }[] = [];
  pickerAccounts.forEach((a, i) => {
    row.push({
      text: `${a.name.slice(0, 18)} (${a.currency})`,
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
  messageId: number,
  /** When set (e.g. inline category button), avoids relying on a stale `draft._categories` snapshot for `find`. */
  pickedCategory?: { id: string; name: string; kind: string }
): Promise<void> {
  const catId = typeof draft.categoryId === "string" ? draft.categoryId : "";
  const cat = pickedCategory ?? categories.find((c) => c.id === catId);
  if (accounts.length === 0) {
    await deleteTelegramBotSession(deps.db, chatIdStr);
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "no_accounts_available"));
    return;
  }
  const accIdDraft = typeof draft.accountId === "string" ? draft.accountId.trim() : "";
  const accFromDraft = accounts.find((a) => a.id === accIdDraft);
  if (accFromDraft && cat) {
    draft.accountId = accFromDraft.id;
    draft.currency = accFromDraft.currency;
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
  await promptPickAccount(uid, chatIdStr, chatIdNum, locale, draft, accounts, mainCurrency, deps, messageId);
}

async function promptPickAccount(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  draft: Draft,
  accounts: { id: string; name: string; currency: string }[],
  mainCurrency: string,
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  if (accounts.length === 0) {
    await deleteTelegramBotSession(deps.db, chatIdStr);
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "no_accounts_available"));
    return;
  }
  draft.step = "pick_account";
  setPickAccountOrder(draft, accounts.map((a) => a.id));
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
  const text = t(locale, "pick_account", { amountHint: pickListAmountHint(locale, draft, mainCurrency) });
  await telegramEditMessageTextOrSend(deps.fetchTelegram, deps.botToken, chatIdNum, messageId, text, kb(rows));
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
  const isTransfer = draft.txKind === "transfer";
  const intentUpsert: BotIntent = isTransfer
    ? "transfer"
    : draft.direction === "in"
      ? "income"
      : "expense";
  await upsertTelegramBotSession(deps.db, chatIdStr, {
    uid,
    locale,
    intent: intentUpsert,
    step: "confirm",
    draft,
  });
  let body: string;
  if (isTransfer) {
    const amountMinor = typeof draft.amountMinor === "number" ? draft.amountMinor : 0;
    const memo = typeof draft.memo === "string" ? draft.memo : "";
    const fromId = typeof draft.transferFromId === "string" ? draft.transferFromId : "";
    const toId = typeof draft.transferToId === "string" ? draft.transferToId : "";
    const fromCur = (typeof draft.transferFromCurrency === "string" ? draft.transferFromCurrency : mainCurrency).toUpperCase();
    const toCur = (typeof draft.transferToCurrency === "string" ? draft.transferToCurrency : mainCurrency).toUpperCase();
    const fromName = accounts.find((a) => a.id === fromId)?.name ?? fromId;
    const toName = accounts.find((a) => a.id === toId)?.name ?? toId;
    const inMinorRaw = draft.amountMinorTo;
    const inMinor =
      typeof inMinorRaw === "number" && Number.isFinite(inMinorRaw) && inMinorRaw > 0
        ? Math.round(inMinorRaw)
        : amountMinor;
    const dash = "—";
    body = t(locale, "confirm_transfer", {
      fromAcc: fromName,
      toAcc: toName,
      fromCur,
      toCur,
      amountOut: formatLedgerAmountMinor(amountMinor, fromCur),
      amountIn: formatLedgerAmountMinor(inMinor, toCur),
      memo: memo.trim().length > 0 ? memo : dash,
    });
  } else {
    const amountMinor = typeof draft.amountMinor === "number" ? draft.amountMinor : 0;
    const memo = typeof draft.memo === "string" ? draft.memo : "";
    const direction = draft.direction === "in" ? "in" : "out";
    const accId = typeof draft.accountId === "string" ? draft.accountId : "";
    const catId = typeof draft.categoryId === "string" ? draft.categoryId : "";
    const cur = (typeof draft.currency === "string" ? draft.currency : mainCurrency).toUpperCase();
    const accName = accounts.find((a) => a.id === accId)?.name ?? accId;
    const catName = categories.find((c) => c.id === catId)?.name ?? catId;
    body = t(locale, "confirm_transaction", {
      direction: direction === "in" ? "IN" : "OUT",
      amount: formatLedgerAmountMinor(amountMinor, cur),
      memo,
      account: accName,
      category: catName,
    });
  }
  const rows = [[{ text: "✓", callback_data: "cf" }, { text: "✗", callback_data: "cx" }]];
  await telegramEditMessageTextOrSend(
    deps.fetchTelegram,
    deps.botToken,
    chatIdNum,
    messageId,
    body,
    kb(rows)
  );
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
  if (!accId || !catId || amountMinor <= 0 || memo.trim().length === 0) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    await deleteTelegramBotSession(deps.db, chatIdStr);
    return;
  }
  await createStandardLedgerTransaction(deps.db, uid, {
    transactionDate: ymd,
    amountMinor,
    direction,
    currency: cur,
    accountId: accId,
    categoryId: catId,
    memo,
  });
  const postedKey: MessageKey = direction === "in" ? "posted_income" : "posted_expense";
  const msgPosted = t(locale, postedKey, { memo, amount: formatLedgerAmountMinor(amountMinor, cur) });
  await deleteTelegramBotSession(deps.db, chatIdStr);
  await telegramEditMessageTextOrSend(
    deps.fetchTelegram,
    deps.botToken,
    chatIdNum,
    messageId,
    msgPosted
  );
}

async function postTransferTx(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  draft: Draft,
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  const ymd = await userTodayYmd(deps.db, uid);
  const fromId = typeof draft.transferFromId === "string" ? draft.transferFromId : "";
  const toId = typeof draft.transferToId === "string" ? draft.transferToId : "";
  const fromCur = (typeof draft.transferFromCurrency === "string" ? draft.transferFromCurrency : "").toUpperCase();
  const toCur = (typeof draft.transferToCurrency === "string" ? draft.transferToCurrency : "").toUpperCase();
  const outAmt = typeof draft.amountMinor === "number" ? draft.amountMinor : 0;
  const inAmtRaw = draft.amountMinorTo;
  const inAmt =
    typeof inAmtRaw === "number" && Number.isFinite(inAmtRaw) && inAmtRaw > 0 ? Math.round(inAmtRaw) : outAmt;
  const memo = typeof draft.memo === "string" ? draft.memo : "";
  if (!fromId || !toId || outAmt <= 0) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    await deleteTelegramBotSession(deps.db, chatIdStr);
    return;
  }
  await createTransferLegPairAdmin(deps.db, uid, {
    transactionDate: ymd,
    fromAccountId: fromId,
    fromCurrency: fromCur,
    fromAmountMinor: outAmt,
    toAccountId: toId,
    toCurrency: toCur,
    toAmountMinor: inAmt,
    memo: memo.trim().length > 0 ? memo : null,
  });
  const amtLabel =
    fromCur === toCur
      ? formatLedgerAmountMinor(outAmt, fromCur)
      : `${formatLedgerAmountMinor(outAmt, fromCur)} → ${formatLedgerAmountMinor(inAmt, toCur)}`;
  await deleteTelegramBotSession(deps.db, chatIdStr);
  await telegramEditMessageTextOrSend(
    deps.fetchTelegram,
    deps.botToken,
    chatIdNum,
    messageId,
    t(locale, "posted_transfer", { amount: amtLabel })
  );
}

async function finalizeSpendCategoryResolution(
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
  const prefs = await loadTelegramBotPreferences(deps.db, uid);
  const kind = draft.direction === "in" ? "income" : "expense";
  if (!categories.some((c) => c.kind === kind)) {
    await deleteTelegramBotSession(deps.db, chatIdStr);
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "no_categories_available"));
    return;
  }
  let catId = typeof draft.categoryId === "string" ? draft.categoryId : "";
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
    await promptPickCategory(uid, chatIdStr, chatIdNum, locale, draft, categories, mainCurrency, deps, messageId);
    return;
  }
  draft.categoryId = catId;
  await advanceAfterCategory(uid, chatIdStr, chatIdNum, locale, draft, accounts, categories, mainCurrency, deps, messageId);
}

export async function handlePhoto(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  prefs: Awaited<ReturnType<typeof loadTelegramBotPreferences>>,
  message: TelegramMessage,
  deps: TelegramHandleDeps
): Promise<void> {
  const caption = typeof message.caption === "string" ? message.caption : "";
  const locale = pickBotLocale({
    localeOverride: prefs.localeOverride,
    userText: caption || undefined,
    message,
  });
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "processing_photo"));
  const photos = message.photo ?? [];
  if (photos.length === 0) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    return;
  }
  const best = photos.reduce((a, b) => ((b.height ?? 0) > (a.height ?? 0) ? b : a), photos[0]);
  const fileId = typeof best?.file_id === "string" ? best.file_id : "";
  const accounts = await loadAccountsForBot(deps.db, uid);
  const categories = await loadCategoriesForBot(deps.db, uid);
  const mainCurrency = await loadMainCurrency(deps.db, uid);
  const genkitToolContext = { db: deps.db, uid };
  let parsed: Awaited<ReturnType<typeof parseReceiptImageWithOptionalGemini>> = null;
  if (caption.trim().length > 0) {
    parsed = await parseReceiptCaptionWithOptionalGemini(
      deps.geminiApiKey,
      mainCurrency,
      caption,
      categories,
      accounts,
      locale,
      genkitToolContext
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
          categories,
          accounts,
          locale,
          genkitToolContext
        );
      }
    }
  }
  if (!parsed) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    return;
  }
  await beginSpendFlow(uid, chatIdStr, chatIdNum, locale, parsed, accounts, categories, mainCurrency, deps, 0);
}

export async function handleVoice(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  prefs: Awaited<ReturnType<typeof loadTelegramBotPreferences>>,
  message: TelegramMessage,
  deps: TelegramHandleDeps
): Promise<void> {
  let locale = pickBotLocale({ localeOverride: prefs.localeOverride, message });
  await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "processing_voice"));
  const fileId = typeof message.voice?.file_id === "string" ? message.voice.file_id : "";
  const accounts = await loadAccountsForBot(deps.db, uid);
  const categories = await loadCategoriesForBot(deps.db, uid);
  const mainCurrency = await loadMainCurrency(deps.db, uid);
  const genkitToolContext = { db: deps.db, uid };
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
          categories,
          accounts,
          locale,
          genkitToolContext
        );
      }
    }
  }
  if (!parsed || parsed.amountMinor == null || parsed.amountMinor <= 0) {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "parse_error"));
    return;
  }
  locale = pickBotLocale({
    localeOverride: prefs.localeOverride,
    userText: parsed.memo,
    message,
  });
  await beginSpendFlow(uid, chatIdStr, chatIdNum, locale, parsed, accounts, categories, mainCurrency, deps, 0);
}

export async function beginSpendFlow(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  parsed: NluParseResult,
  accounts: { id: string; name: string; currency: string }[],
  categories: { id: string; name: string; kind: string }[],
  mainCurrency: string,
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  let accId = parsed.accountId;
  if (accId && !accounts.some((a) => a.id === accId)) accId = undefined;

  const draft: Draft = {
    memo: parsed.memo,
    direction: parsed.direction,
    intent: parsed.direction === "in" ? "income" : "expense",
    categoryId: parsed.categoryId,
    accountId: accId,
    _accounts: accounts,
    _categories: categories,
  };

  if (parsed.amountMinor == null || parsed.amountMinor <= 0) {
    draft.step = "await_amount";
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale,
      intent: parsed.direction === "in" ? "income" : "expense",
      step: "await_amount",
      draft,
    });
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "need_amount"));
    return;
  }
  draft.amountMinor = parsed.amountMinor;

  if (!parsed.memo || parsed.memo.trim().length === 0) {
    draft.step = "await_memo";
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale,
      intent: parsed.direction === "in" ? "income" : "expense",
      step: "await_memo",
      draft,
    });
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "need_memo"));
    return;
  }

  draft.memo = parsed.memo.trim().slice(0, 200);
  await finalizeSpendCategoryResolution(
    uid,
    chatIdStr,
    chatIdNum,
    locale,
    draft,
    accounts,
    categories,
    mainCurrency,
    deps,
    messageId
  );
}

async function promptPickCategory(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  locale: BotLocale,
  draft: Draft,
  categories: { id: string; name: string; kind: string }[],
  mainCurrency: string,
  deps: TelegramHandleDeps,
  messageId: number
): Promise<void> {
  const kind = draft.direction === "in" ? "income" : "expense";
  const filtered = categories.filter((c) => c.kind === kind);
  if (filtered.length === 0) {
    await deleteTelegramBotSession(deps.db, chatIdStr);
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(locale, "no_categories_available"));
    return;
  }
  setPickCategoryOrder(draft, filtered.map((c) => c.id));
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
  const textBody = t(locale, "pick_category", { amountHint: pickListAmountHint(locale, draft, mainCurrency) });
  await telegramEditMessageTextOrSend(deps.fetchTelegram, deps.botToken, chatIdNum, messageId, textBody, kb(rows));
}

export async function handleDialogText(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  prefs: Awaited<ReturnType<typeof loadTelegramBotPreferences>>,
  text: string,
  message: TelegramMessage,
  deps: TelegramHandleDeps
): Promise<void> {
  const accounts = await loadAccountsForBot(deps.db, uid);
  const categories = await loadCategoriesForBot(deps.db, uid);
  const mainCurrency = await loadMainCurrency(deps.db, uid);
  const genkitToolContext = { db: deps.db, uid };
  let session = await loadTelegramBotSession(deps.db, chatIdStr);
  const fallbackLoc =
    session?.locale === "es" || session?.locale === "en"
      ? session.locale
      : pickBotLocale({ localeOverride: prefs.localeOverride, userText: text, message });
  let loc: BotLocale;
  if (chatIdStr.startsWith("app_")) {
    loc = pickBotLocale({ localeOverride: prefs.localeOverride, userText: text, message });
  } else {
    const detectedLoc = await detectStrictTextLocale(text, fallbackLoc, deps, chatIdNum);
    if (!detectedLoc) return;
    loc = detectedLoc;
  }

  const norm = text.trim().toLowerCase();

  if (norm === "/help") {
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(loc, "help"));
    return;
  }
  if (norm === "/cancel") {
    await deleteTelegramBotSession(deps.db, chatIdStr);
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(loc, "cancelled"));
    return;
  }

  if (
    session &&
    (session.step === "confirm" ||
      session.step === "pick_account" ||
      session.step === "pick_category") &&
    norm !== "/transfer"
  ) {
    await deleteTelegramBotSession(deps.db, chatIdStr);
    session = null;
  }

  if (norm === "/transfer") {
    const draft: Draft = {
      step: "transfer_from",
      _accounts: accounts,
      _categories: categories,
    };
    setTransferFromOrder(draft, accounts.map((a) => a.id));
    await upsertTelegramBotSession(deps.db, chatIdStr, {
      uid,
      locale: loc,
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
    await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(loc, "pick_transfer_from"), kb(rows));
    return;
  }

  if (
    session &&
    (session.intent === "expense" || session.intent === "income") &&
    session.step === "await_amount"
  ) {
    if (deps.geminiApiKey?.trim()) {
      const prev = snapshotFromLegacySpendDraft(session.draft as Draft);
      const cont = await continueDialogWithGemini(
        deps.geminiApiKey,
        mainCurrency,
        text,
        prev,
        categories,
        accounts,
        loc,
        genkitToolContext
      );
      if (!cont) {
        await logGeminiNullThenGenericError(deps, chatIdNum, loc, chatIdStr, "await_amount_continue");
        return;
      }
      if (cont.dialogIntent !== "transaction") {
        await deleteTelegramBotSession(deps.db, chatIdStr);
        const msg =
          cont.snap.assistantMessage.trim() ||
          (cont.dialogIntent === "greeting"
            ? t(localeForSmallTalkReply(norm), "small_talk_hint")
            : t(loc, "help"));
        await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, truncateForTelegram(msg));
        return;
      }
      await finalizeTelegramGeminiSnapshotFromModelSnap(
        uid,
        chatIdStr,
        chatIdNum,
        loc,
        prefs,
        cont.snap,
        session.draft as Draft,
        accounts,
        categories,
        mainCurrency,
        deps
      );
      return;
    }
    const draft = { ...(session.draft as Draft) };
    const amount = parseAmountMinorFromFollowUp(mainCurrency, text);
    if (amount == null || amount <= 0) {
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(loc, "need_amount"));
      return;
    }
    draft.amountMinor = amount;
    const memo = typeof draft.memo === "string" ? draft.memo.trim() : "";
    if (!memo) {
      draft.step = "await_memo";
      await upsertTelegramBotSession(deps.db, chatIdStr, {
        uid,
        locale: loc,
        intent: session.intent,
        step: "await_memo",
        draft,
      });
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(loc, "need_memo"));
      return;
    }
    draft.memo = memo;
    draft._accounts = accounts;
    draft._categories = categories;
    await finalizeSpendCategoryResolution(
      uid,
      chatIdStr,
      chatIdNum,
      loc,
      draft,
      accounts,
      categories,
      mainCurrency,
      deps,
      0
    );
    return;
  }

  if (
    session &&
    (session.intent === "expense" || session.intent === "income") &&
    session.step === "await_memo"
  ) {
    if (deps.geminiApiKey?.trim()) {
      const prev = snapshotFromLegacySpendDraft(session.draft as Draft);
      const cont = await continueDialogWithGemini(
        deps.geminiApiKey,
        mainCurrency,
        text,
        prev,
        categories,
        accounts,
        loc,
        genkitToolContext
      );
      if (!cont) {
        await logGeminiNullThenGenericError(deps, chatIdNum, loc, chatIdStr, "await_memo_continue");
        return;
      }
      if (cont.dialogIntent !== "transaction") {
        await deleteTelegramBotSession(deps.db, chatIdStr);
        const msg =
          cont.snap.assistantMessage.trim() ||
          (cont.dialogIntent === "greeting"
            ? t(localeForSmallTalkReply(norm), "small_talk_hint")
            : t(loc, "help"));
        await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, truncateForTelegram(msg));
        return;
      }
      await finalizeTelegramGeminiSnapshotFromModelSnap(
        uid,
        chatIdStr,
        chatIdNum,
        loc,
        prefs,
        cont.snap,
        session.draft as Draft,
        accounts,
        categories,
        mainCurrency,
        deps
      );
      return;
    }
    const draft = { ...(session.draft as Draft) };
    draft.memo = text.trim().slice(0, 200);
    if (!draft.memo) {
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(loc, "need_memo"));
      return;
    }
    draft._accounts = accounts;
    draft._categories = categories;
    await finalizeSpendCategoryResolution(
      uid,
      chatIdStr,
      chatIdNum,
      loc,
      draft,
      accounts,
      categories,
      mainCurrency,
      deps,
      0
    );
    return;
  }

  if (session?.intent === "transfer" && session.step === "transfer_amount") {
    const draft = { ...(session.draft as Draft) };
    if (deps.geminiApiKey?.trim()) {
      const prev = snapshotFromTransferWizardDraft(draft);
      const cont = await continueDialogWithGemini(
        deps.geminiApiKey,
        mainCurrency,
        text,
        prev,
        categories,
        accounts,
        loc,
        genkitToolContext
      );
      if (!cont) {
        await logGeminiNullThenGenericError(deps, chatIdNum, loc, chatIdStr, "transfer_amount_continue");
        return;
      }
      if (cont.dialogIntent !== "transaction") {
        await deleteTelegramBotSession(deps.db, chatIdStr);
        const msg =
          cont.snap.assistantMessage.trim() ||
          (cont.dialogIntent === "greeting"
            ? t(localeForSmallTalkReply(norm), "small_talk_hint")
            : t(loc, "help"));
        await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, truncateForTelegram(msg));
        return;
      }
      const { ok, snap: validated } = validateTransactionSnapshot(cont.snap, categories, accounts);
      if (ok) {
        const fromId = validated.transferFromId ?? "";
        const toId = validated.transferToId ?? "";
        const fromA = accounts.find((a) => a.id === fromId);
        const toA = accounts.find((a) => a.id === toId);
        const outAmt = validated.amountMinor ?? 0;
        const inAmt =
          validated.amountMinorTo != null &&
          Number.isFinite(validated.amountMinorTo) &&
          validated.amountMinorTo > 0
            ? Math.round(validated.amountMinorTo)
            : outAmt;
        if (!fromA || !toA || outAmt <= 0) {
          await finalizeTelegramGeminiSnapshotFromModelSnap(
            uid,
            chatIdStr,
            chatIdNum,
            loc,
            prefs,
            cont.snap,
            draft,
            accounts,
            categories,
            mainCurrency,
            deps
          );
          return;
        }
        const ymd = await userTodayYmd(deps.db, uid);
        const memo = (validated.memo ?? "").trim();
        await createTransferLegPairAdmin(deps.db, uid, {
          transactionDate: ymd,
          fromAccountId: fromId,
          fromCurrency: fromA.currency.toUpperCase(),
          fromAmountMinor: outAmt,
          toAccountId: toId,
          toCurrency: toA.currency.toUpperCase(),
          toAmountMinor: inAmt,
          memo: memo.length > 0 ? memo : null,
        });
        const amtLabel =
          fromA.currency === toA.currency
            ? formatLedgerAmountMinor(outAmt, fromA.currency)
            : `${formatLedgerAmountMinor(outAmt, fromA.currency)} → ${formatLedgerAmountMinor(inAmt, toA.currency)}`;
        await telegramSendMessage(
          deps.fetchTelegram,
          deps.botToken,
          chatIdNum,
          t(loc, "posted_transfer", { amount: amtLabel })
        );
        await deleteTelegramBotSession(deps.db, chatIdStr);
        return;
      }
      await finalizeTelegramGeminiSnapshotFromModelSnap(
        uid,
        chatIdStr,
        chatIdNum,
        loc,
        prefs,
        cont.snap,
        draft,
        accounts,
        categories,
        mainCurrency,
        deps
      );
      return;
    }
    const parsed = await parseTransactionLineWithOptionalGemini(
      deps.geminiApiKey,
      mainCurrency,
      text,
      categories,
      accounts,
      loc,
      genkitToolContext
    );
    if (
      !parsed ||
      parsed.direction !== "out" ||
      parsed.amountMinor == null ||
      parsed.amountMinor <= 0
    ) {
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(loc, "amount_missing"));
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
      t(loc, "posted_transfer", { amount: formatLedgerAmountMinor(parsed.amountMinor, fromCur) })
    );
    await deleteTelegramBotSession(deps.db, chatIdStr);
    return;
  }

  if (session?.step === "gemini_collect") {
    if (!deps.geminiApiKey?.trim()) {
      await deleteTelegramBotSession(deps.db, chatIdStr);
      await telegramSendMessage(
        deps.fetchTelegram,
        deps.botToken,
        chatIdNum,
        t(loc, "conversational_parse_requires_gemini")
      );
      return;
    }

    const prevDraft = session.draft as Draft;
    const prev =
      snapshotFromDraftRecord(prevDraft._geminiSnapshot) ?? EMPTY_TRANSACTION_SNAPSHOT;
    const cont = await continueDialogWithGemini(
      deps.geminiApiKey,
      mainCurrency,
      text,
      prev,
      categories,
      accounts,
      loc,
      genkitToolContext
    );
    if (!cont) {
      await logGeminiNullThenGenericError(deps, chatIdNum, loc, chatIdStr, "gemini_collect_continue");
      return;
    }
    if (cont.dialogIntent !== "transaction") {
      await deleteTelegramBotSession(deps.db, chatIdStr);
      const msg =
        cont.snap.assistantMessage.trim() ||
        (cont.dialogIntent === "greeting"
          ? t(localeForSmallTalkReply(norm), "small_talk_hint")
          : t(loc, "help"));
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, truncateForTelegram(msg));
      return;
    }
    await finalizeTelegramGeminiSnapshotFromModelSnap(
      uid,
      chatIdStr,
      chatIdNum,
      loc,
      prefs,
      cont.snap,
      prevDraft,
      accounts,
      categories,
      mainCurrency,
      deps
    );
    return;
  }

  if (deps.geminiApiKey?.trim()) {
    const analysis = await analyzeFirstMessageWithGemini(
      deps.geminiApiKey,
      mainCurrency,
      text,
      categories,
      accounts,
      loc,
      genkitToolContext
    );
    if (analysis) {
      if (analysis.intent === "greeting") {
        const msg =
          analysis.quickReply.trim() ||
          t(localeForSmallTalkReply(norm), "small_talk_hint");
        await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, truncateForTelegram(msg));
        return;
      }
      if (analysis.intent === "question") {
        const msg = analysis.quickReply.trim() || t(loc, "help");
        await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, truncateForTelegram(msg));
        return;
      }
      let snap = analysis.transaction ?? EMPTY_TRANSACTION_SNAPSHOT;
      if (!analysis.transaction && analysis.quickReply.trim()) {
        snap = { ...EMPTY_TRANSACTION_SNAPSHOT, assistantMessage: analysis.quickReply };
      }
      await finalizeTelegramGeminiSnapshotFromModelSnap(
        uid,
        chatIdStr,
        chatIdNum,
        loc,
        prefs,
        snap,
        session ? { ...(session.draft as Draft) } : {},
        accounts,
        categories,
        mainCurrency,
        deps
      );
      return;
    }
    const cont = await continueDialogWithGemini(
      deps.geminiApiKey,
      mainCurrency,
      text,
      EMPTY_TRANSACTION_SNAPSHOT,
      categories,
      accounts,
      loc,
      genkitToolContext
    );
    if (!cont) {
      await logGeminiNullThenGenericError(deps, chatIdNum, loc, chatIdStr, "first_message_empty_snapshot_fallback");
      return;
    }
    if (cont.dialogIntent !== "transaction") {
      const msg =
        cont.snap.assistantMessage.trim() ||
        (cont.dialogIntent === "greeting"
          ? t(localeForSmallTalkReply(norm), "small_talk_hint")
          : t(loc, "help"));
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, truncateForTelegram(msg));
      return;
    }
    await finalizeTelegramGeminiSnapshotFromModelSnap(
      uid,
      chatIdStr,
      chatIdNum,
      loc,
      prefs,
      cont.snap,
      session ? { ...(session.draft as Draft) } : {},
      accounts,
      categories,
      mainCurrency,
      deps
    );
    return;
  }

  if (!deps.geminiApiKey?.trim()) {
    const parsed = await parseTransactionLineWithOptionalGemini(
      deps.geminiApiKey,
      mainCurrency,
      text,
      categories,
      accounts,
      loc,
      genkitToolContext
    );
    if (!parsed) {
      if (suggestsConversationalParse(text)) {
        await telegramSendMessage(
          deps.fetchTelegram,
          deps.botToken,
          chatIdNum,
          t(loc, "conversational_parse_requires_gemini")
        );
        return;
      }
      const key: MessageKey = looksLikeSmallTalk(norm) ? "small_talk_hint" : "amount_missing";
      const replyLoc = key === "small_talk_hint" ? localeForSmallTalkReply(norm) : loc;
      await telegramSendMessage(deps.fetchTelegram, deps.botToken, chatIdNum, t(replyLoc, key));
      return;
    }

    if (parsed.amountMinor == null || parsed.amountMinor <= 0) {
      await beginSpendFlow(uid, chatIdStr, chatIdNum, loc, parsed, accounts, categories, mainCurrency, deps, 0);
      return;
    }

    await beginSpendFlow(uid, chatIdStr, chatIdNum, loc, parsed, accounts, categories, mainCurrency, deps, 0);
  }
}
