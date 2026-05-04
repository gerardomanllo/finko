export type DialogIntent = "greeting" | "question" | "transaction";

/** One model snapshot of a standard or transfer transaction (full state each turn). */
export type GeminiTransactionSnapshot = {
  complete: boolean;
  assistantMessage: string;
  txKind: "standard" | "transfer" | null;
  direction: "in" | "out" | null;
  amountMinor: number | null;
  /** Second leg minor units for cross-currency transfer (optional). */
  amountMinorTo: number | null;
  memo: string | null;
  categoryId: string | null;
  accountId: string | null;
  transferFromId: string | null;
  transferToId: string | null;
};

export const EMPTY_TRANSACTION_SNAPSHOT: GeminiTransactionSnapshot = {
  complete: false,
  assistantMessage: "",
  txKind: null,
  direction: null,
  amountMinor: null,
  amountMinorTo: null,
  memo: null,
  categoryId: null,
  accountId: null,
  transferFromId: null,
  transferToId: null,
};

function parseAmountMinor(v: unknown): number | null {
  if (v === null || v === undefined) return null;
  if (typeof v === "number") {
    const n = Math.round(v);
    return Number.isFinite(n) && n > 0 ? n : null;
  }
  if (typeof v === "string") {
    const n = Math.round(Number(v.trim()));
    return Number.isFinite(n) && n > 0 ? n : null;
  }
  return null;
}

function strOrNull(v: unknown): string | null {
  if (v === null || v === undefined) return null;
  if (typeof v === "string") {
    const s = v.trim();
    return s.length > 0 ? s : null;
  }
  return null;
}

/** Build snapshot to continue from photo/voice `beginSpendFlow` draft (await_amount / await_memo). */
export function snapshotFromLegacySpendDraft(draft: Record<string, unknown>): GeminiTransactionSnapshot {
  const direction: "in" | "out" = draft.direction === "in" ? "in" : "out";
  const amt =
    typeof draft.amountMinor === "number" && Number.isFinite(draft.amountMinor)
      ? Math.round(draft.amountMinor)
      : null;
  let memo: string | null = null;
  if (typeof draft.memo === "string" && draft.memo.trim().length > 0) {
    memo = draft.memo.trim();
  }
  let categoryId: string | null = null;
  if (typeof draft.categoryId === "string" && draft.categoryId.trim().length > 0) {
    categoryId = draft.categoryId.trim();
  }
  let accountId: string | null = null;
  if (typeof draft.accountId === "string" && draft.accountId.trim().length > 0) {
    accountId = draft.accountId.trim();
  }
  return {
    ...EMPTY_TRANSACTION_SNAPSHOT,
    txKind: "standard",
    direction,
    amountMinor: amt && amt > 0 ? amt : null,
    memo,
    categoryId,
    accountId,
  };
}

/** Build snapshot after `/transfer` keyboard picked accounts (user is entering amount). */
export function snapshotFromTransferWizardDraft(draft: Record<string, unknown>): GeminiTransactionSnapshot {
  let fromId: string | null = null;
  let toId: string | null = null;
  if (typeof draft.transferFromId === "string" && draft.transferFromId.trim().length > 0) {
    fromId = draft.transferFromId.trim();
  }
  if (typeof draft.transferToId === "string" && draft.transferToId.trim().length > 0) {
    toId = draft.transferToId.trim();
  }
  return {
    ...EMPTY_TRANSACTION_SNAPSHOT,
    txKind: "transfer",
    transferFromId: fromId,
    transferToId: toId,
  };
}

export function snapshotFromUnknown(parsed: Record<string, unknown>): GeminiTransactionSnapshot {
  const txKind = parsed.txKind === "transfer" || parsed.txKind === "standard" ? parsed.txKind : null;
  const direction = parsed.direction === "in" || parsed.direction === "out" ? parsed.direction : null;
  const memoRaw = strOrNull(parsed.memo);
  return {
    complete: parsed.complete === true,
    assistantMessage:
      typeof parsed.assistantMessage === "string" ? parsed.assistantMessage.trim().slice(0, 3500) : "",
    txKind,
    direction,
    amountMinor: parseAmountMinor(parsed.amountMinor),
    amountMinorTo: parseAmountMinor(parsed.amountMinorTo),
    memo: memoRaw,
    categoryId: strOrNull(parsed.categoryId),
    accountId: strOrNull(parsed.accountId),
    transferFromId: strOrNull(parsed.transferFromId),
    transferToId: strOrNull(parsed.transferToId),
  };
}

/** Read `_geminiSnapshot` from a session draft (if present). */
export function snapshotFromDraftRecord(raw: unknown): GeminiTransactionSnapshot | null {
  if (!raw || typeof raw !== "object") return null;
  return snapshotFromUnknown(raw as Record<string, unknown>);
}

export type ContinueDialogWithGeminiResult = {
  dialogIntent: DialogIntent;
  snap: GeminiTransactionSnapshot;
};

export type FirstMessageAnalysis = {
  intent: DialogIntent;
  quickReply: string;
  transaction: GeminiTransactionSnapshot | null;
};
