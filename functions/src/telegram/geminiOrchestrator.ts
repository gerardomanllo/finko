import type { AccountRow, CategoryRow } from "./ledgerToolkit";
import type { BotLocale } from "./sessions";
import {
  analyzeFirstMessageWithGenkit,
  continueDialogWithGenkit,
  detectMessageLanguageWithGenkit,
} from "./genkit/dialogGenkit";
import type { TelegramGenkitToolContext } from "./genkit/types";
import { looksLikeSmallTalk } from "./smallTalk";
import { parseSpendLine } from "./parseTxText";
import type {
  ContinueDialogWithGeminiResult,
  DialogIntent,
  FirstMessageAnalysis,
  GeminiTransactionSnapshot,
} from "./telegramGeminiSnapshot";

export type {
  ContinueDialogWithGeminiResult,
  DialogIntent,
  FirstMessageAnalysis,
  GeminiTransactionSnapshot,
} from "./telegramGeminiSnapshot";
export {
  EMPTY_TRANSACTION_SNAPSHOT,
  snapshotFromDraftRecord,
  snapshotFromLegacySpendDraft,
  snapshotFromTransferWizardDraft,
  snapshotFromUnknown,
} from "./telegramGeminiSnapshot";

export type { TelegramGenkitToolContext } from "./genkit/types";

/** Heuristic intent when the model is unavailable. */
export function classifyDialogIntentHeuristic(norm: string, raw: string, mainCurrency: string): DialogIntent {
  if (looksLikeSmallTalk(norm)) return "greeting";
  const line = raw.trim();
  const cur = mainCurrency.trim().length > 0 ? mainCurrency.trim().toUpperCase() : "MXN";
  if (parseSpendLine(cur, line)) return "transaction";
  if (
    /\b(transfer|transferir|xfer|move|enviar|mandé|mande|from\s+.+\s+to)\b/i.test(line)
  ) {
    return "transaction";
  }
  if (
    /\b(gast[eé]|compr[eé]|pagu[eé]|spent|paid|bought|pague|ingreso|salario|nómina|nomina)\b/i.test(
      line
    )
  ) {
    return "transaction";
  }
  if (/^\s*(\+?\s*[\d]{1,12})/.test(line) && /[a-záéíóúñ]{2,}/i.test(line)) return "transaction";
  if (/^(what|how|why|when|where|can you|do you|qué|cómo|por\s*qué|quién)\b/i.test(norm)) {
    return "question";
  }
  return "transaction";
}

function validateIds(
  snap: GeminiTransactionSnapshot,
  categories: CategoryRow[],
  accounts: AccountRow[]
): GeminiTransactionSnapshot {
  const accountIds = new Set(accounts.map((a) => a.id));
  const fixAcc = (id: string | null) => (id && accountIds.has(id) ? id : null);
  const fixCat = (id: string | null, dir: "in" | "out") => {
    if (!id) return null;
    const kind = dir === "in" ? "income" : "expense";
    return categories.some((c) => c.id === id && c.kind === kind) ? id : null;
  };
  const dir: "in" | "out" = snap.direction === "in" ? "in" : "out";
  return {
    ...snap,
    accountId: fixAcc(snap.accountId),
    transferFromId: fixAcc(snap.transferFromId),
    transferToId: fixAcc(snap.transferToId),
    categoryId: snap.txKind === "standard" ? fixCat(snap.categoryId, dir) : null,
  };
}

/** Server-side completeness (never trust model's `complete` alone). */
export function validateTransactionSnapshot(
  snap: GeminiTransactionSnapshot,
  categories: CategoryRow[],
  accounts: AccountRow[]
): { ok: boolean; snap: GeminiTransactionSnapshot } {
  let s: GeminiTransactionSnapshot = { ...snap };
  if (s.txKind == null && s.transferFromId && s.transferToId) {
    s.txKind = "transfer";
  }
  if (s.txKind == null && s.direction && (s.categoryId != null || (s.memo ?? "").trim().length > 0)) {
    s.txKind = "standard";
  }
  s = validateIds(s, categories, accounts);
  if (s.txKind === "transfer") {
    const from = s.transferFromId;
    const to = s.transferToId;
    const amt = s.amountMinor;
    if (!from || !to || from === to || amt == null || amt <= 0) {
      return { ok: false, snap: { ...s, complete: false } };
    }
    const fromA = accounts.find((a) => a.id === from);
    const toA = accounts.find((a) => a.id === to);
    if (!fromA || !toA) return { ok: false, snap: { ...s, complete: false } };
    if (fromA.currency === toA.currency) {
      return { ok: true, snap: { ...s, complete: true, amountMinorTo: null } };
    }
    const toAmt = s.amountMinorTo;
    if (toAmt == null || toAmt <= 0) {
      return { ok: false, snap: { ...s, complete: false } };
    }
    return { ok: true, snap: { ...s, complete: true } };
  }
  if (s.txKind === "standard") {
    const dir = s.direction === "in" ? "in" : "out";
    const amt = s.amountMinor;
    const memo = (s.memo ?? "").trim();
    const cat = s.categoryId;
    const acc = s.accountId;
    if (amt == null || amt <= 0 || memo.length === 0 || !cat || !acc) {
      return { ok: false, snap: { ...s, complete: false } };
    }
    const kind = dir === "in" ? "income" : "expense";
    if (!categories.some((c) => c.id === cat && c.kind === kind)) {
      return { ok: false, snap: { ...s, complete: false } };
    }
    if (!accounts.some((a) => a.id === acc)) {
      return { ok: false, snap: { ...s, complete: false } };
    }
    return { ok: true, snap: { ...s, complete: true } };
  }
  return { ok: false, snap: { ...s, complete: false } };
}

/**
 * Single Genkit call for a new user message: intent + (if transaction) first extraction pass.
 */
export async function analyzeFirstMessageWithGemini(
  apiKey: string,
  mainCurrency: string,
  userText: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  locale: BotLocale,
  toolContext?: TelegramGenkitToolContext | null
): Promise<FirstMessageAnalysis | null> {
  return analyzeFirstMessageWithGenkit(
    apiKey,
    mainCurrency,
    userText,
    categories,
    accounts,
    locale,
    toolContext ?? null
  );
}

/**
 * Continuation turn: merge previous state with the new user message.
 */
export async function continueDialogWithGemini(
  apiKey: string,
  mainCurrency: string,
  userText: string,
  previous: GeminiTransactionSnapshot,
  categories: CategoryRow[],
  accounts: AccountRow[],
  locale: BotLocale,
  toolContext?: TelegramGenkitToolContext | null
): Promise<ContinueDialogWithGeminiResult | null> {
  return continueDialogWithGenkit(
    apiKey,
    mainCurrency,
    userText,
    previous,
    categories,
    accounts,
    locale,
    toolContext ?? null
  );
}

/** Apply defaults from bot preferences when the model left account/category null but amount+memo exist. */
export function applyPreferenceDefaults(
  snap: GeminiTransactionSnapshot,
  prefs: {
    defaultAccountId?: string;
    defaultExpenseCategoryId?: string;
    defaultIncomeCategoryId?: string;
  },
  categories: CategoryRow[],
  accounts: AccountRow[]
): GeminiTransactionSnapshot {
  if (snap.txKind !== "standard") return snap;
  const dir = snap.direction === "in" ? "in" : "out";
  let accountId = snap.accountId;
  let categoryId = snap.categoryId;
  const defAcc = prefs.defaultAccountId?.trim();
  if (!accountId && defAcc && accounts.some((a) => a.id === defAcc)) {
    accountId = defAcc;
  }
  const defCat =
    dir === "in" ? prefs.defaultIncomeCategoryId?.trim() : prefs.defaultExpenseCategoryId?.trim();
  const kind = dir === "in" ? "income" : "expense";
  if (!categoryId && defCat && categories.some((c) => c.id === defCat && c.kind === kind)) {
    categoryId = defCat;
  }
  return { ...snap, accountId, categoryId };
}

export async function detectMessageLanguageWithGemini(
  apiKey: string,
  userText: string
): Promise<BotLocale | null> {
  const lang = await detectMessageLanguageWithGenkit(apiKey, userText);
  return lang === "es" || lang === "en" ? lang : null;
}
