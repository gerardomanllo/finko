import { FieldValue, Firestore } from "firebase-admin/firestore";

import { resolveAsOfYmd } from "../scheduleNext";
import { touchLedgerSourcesLastChangedAt } from "../userLedgerSync";

const LEDGER_TRANSFER_CATEGORY_ID = "ledger-transfer";

export async function ensureLedgerTransferCategory(db: Firestore, uid: string): Promise<void> {
  const ref = db.doc(`users/${uid}/categories/${LEDGER_TRANSFER_CATEGORY_ID}`);
  await ref.set(
    {
      name: "Transfers",
      kind: "expense",
      iconKey: "swap_horiz",
      sortOrder: -1,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

export type StandardTxParams = {
  transactionDate: string;
  amountMinor: number;
  direction: "in" | "out";
  currency: string;
  accountId: string;
  categoryId: string;
  memo?: string | null;
};

export async function createStandardLedgerTransaction(
  db: Firestore,
  uid: string,
  p: StandardTxParams
): Promise<string> {
  const col = db.collection(`users/${uid}/transactions`);
  const doc = col.doc();
  await doc.set({
    transactionDate: p.transactionDate,
    loadedAt: FieldValue.serverTimestamp(),
    amountMinor: Math.max(0, Math.trunc(p.amountMinor)),
    direction: p.direction,
    currency: p.currency.trim().toUpperCase(),
    accountId: p.accountId.trim(),
    categoryId: p.categoryId.trim(),
    type: "standard",
    memo: p.memo && p.memo.trim().length > 0 ? p.memo.trim() : null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await touchLedgerSourcesLastChangedAt(db, uid);
  return doc.id;
}

export type TransferPairParams = {
  transactionDate: string;
  fromAccountId: string;
  fromCurrency: string;
  fromAmountMinor: number;
  toAccountId: string;
  toCurrency: string;
  toAmountMinor: number;
  memo?: string | null;
};

export async function createTransferLegPairAdmin(
  db: Firestore,
  uid: string,
  p: TransferPairParams
): Promise<{ groupId: string; outLegId: string; inLegId: string }> {
  await ensureLedgerTransferCategory(db, uid);
  const col = db.collection(`users/${uid}/transactions`);
  const groupId = col.doc().id;
  const outRef = col.doc();
  const inRef = col.doc();
  const outId = outRef.id;
  const inId = inRef.id;
  const memo = p.memo && p.memo.trim().length > 0 ? p.memo.trim() : null;

  const batch = db.batch();
  batch.set(outRef, {
    transactionDate: p.transactionDate,
    loadedAt: FieldValue.serverTimestamp(),
    amountMinor: Math.max(0, Math.trunc(p.fromAmountMinor)),
    direction: "out",
    currency: p.fromCurrency.trim().toUpperCase(),
    accountId: p.fromAccountId.trim(),
    categoryId: LEDGER_TRANSFER_CATEGORY_ID,
    type: "transferLeg",
    memo,
    transferGroupId: groupId,
    linkedTransactionId: inId,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  batch.set(inRef, {
    transactionDate: p.transactionDate,
    loadedAt: FieldValue.serverTimestamp(),
    amountMinor: Math.max(0, Math.trunc(p.toAmountMinor)),
    direction: "in",
    currency: p.toCurrency.trim().toUpperCase(),
    accountId: p.toAccountId.trim(),
    categoryId: LEDGER_TRANSFER_CATEGORY_ID,
    type: "transferLeg",
    memo,
    transferGroupId: groupId,
    linkedTransactionId: outId,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  await touchLedgerSourcesLastChangedAt(db, uid);
  return { groupId, outLegId: outId, inLegId: inId };
}

export async function userTodayYmd(db: Firestore, uid: string): Promise<string> {
  const snap = await db.doc(`users/${uid}`).get();
  const tz =
    snap.exists && typeof snap.data()?.timezone === "string" ? snap.data()!.timezone.trim() : "";
  return resolveAsOfYmd({ timezone: tz.length > 0 ? tz : undefined });
}

export type AccountRow = { id: string; name: string; currency: string; type?: string };
export type CategoryRow = { id: string; name: string; kind: string };

export async function loadAccountsForBot(db: Firestore, uid: string): Promise<AccountRow[]> {
  const snap = await db.collection(`users/${uid}/accounts`).get();
  const rows = snap.docs.map((d) => {
    const x = d.data();
    return {
      id: d.id,
      name: typeof x.name === "string" ? x.name : "Account",
      currency:
        typeof x.currency === "string" && x.currency.trim().length > 0 ? x.currency.trim().toUpperCase() : "MXN",
      type: typeof x.type === "string" ? x.type : undefined,
      sortOrder: typeof x.sortOrder === "number" ? x.sortOrder : 0,
    };
  });
  rows.sort((a, b) => a.sortOrder - b.sortOrder);
  return rows.map(({ sortOrder: _, ...rest }) => rest);
}

export async function loadCategoriesForBot(db: Firestore, uid: string): Promise<CategoryRow[]> {
  const snap = await db.collection(`users/${uid}/categories`).get();
  const rows = snap.docs
    .filter((d) => d.id !== LEDGER_TRANSFER_CATEGORY_ID)
    .map((d) => {
      const x = d.data();
      return {
        id: d.id,
        name: typeof x.name === "string" ? x.name : "Category",
        kind: typeof x.kind === "string" ? x.kind : "expense",
        sortOrder: typeof x.sortOrder === "number" ? x.sortOrder : 0,
      };
    });
  rows.sort((a, b) => a.sortOrder - b.sortOrder);
  return rows.map(({ sortOrder: _, ...rest }) => rest);
}

export type AgentPrefsRow = {
  defaultAccountId?: string;
  defaultExpenseCategoryId?: string;
  defaultIncomeCategoryId?: string;
  localeOverride?: string;
};

function parseAgentPrefsMap(raw: Record<string, unknown> | undefined): AgentPrefsRow {
  if (!raw || typeof raw !== "object") return {};
  return {
    defaultAccountId: typeof raw.defaultAccountId === "string" ? raw.defaultAccountId : undefined,
    defaultExpenseCategoryId:
      typeof raw.defaultExpenseCategoryId === "string" ? raw.defaultExpenseCategoryId : undefined,
    defaultIncomeCategoryId:
      typeof raw.defaultIncomeCategoryId === "string" ? raw.defaultIncomeCategoryId : undefined,
    localeOverride: typeof raw.localeOverride === "string" ? raw.localeOverride : undefined,
  };
}

/** Reads `agentPreferences` with legacy `telegramBotPreferences` fallback. */
export async function loadAgentPreferences(db: Firestore, uid: string): Promise<AgentPrefsRow> {
  const snap = await db.doc(`users/${uid}`).get();
  const data = snap.data();
  const agent = data?.agentPreferences as Record<string, unknown> | undefined;
  const legacy = data?.telegramBotPreferences as Record<string, unknown> | undefined;
  return parseAgentPrefsMap(agent ?? legacy);
}

/** @deprecated Use [loadAgentPreferences]. */
export async function loadTelegramBotPreferences(db: Firestore, uid: string): Promise<AgentPrefsRow> {
  return loadAgentPreferences(db, uid);
}

export async function loadMainCurrency(db: Firestore, uid: string): Promise<string> {
  const snap = await db.doc(`users/${uid}`).get();
  const c =
    snap.exists && typeof snap.data()?.mainCurrency === "string"
      ? snap.data()!.mainCurrency.trim().toUpperCase()
      : "";
  return c.length > 0 ? c : "MXN";
}
