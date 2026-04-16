import type { DocumentData, Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { findForexDocWalkBack, foreignMinorToMainMinor } from "./forex";

export type TxPayload = {
  transactionDate: string;
  amountMinor: number;
  direction: "in" | "out";
  currency: string;
  type: string;
  accountId: string;
  categoryId?: string;
};

const AUDIT_KEYS = new Set(["amountMinorMain", "fxRateDateUsed", "updatedAt"]);

/** Skip aggregate work when only audit mirror fields changed. */
export function isAuditOnlyTransactionUpdate(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined
): boolean {
  if (!before || !after) return false;
  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  for (const k of keys) {
    if (AUDIT_KEYS.has(k)) continue;
    if (JSON.stringify(before[k]) !== JSON.stringify(after[k])) return false;
  }
  return true;
}

function monthKeyFromYmd(yyyyMmDd: string): string {
  return yyyyMmDd.slice(0, 7);
}

function dayKeyFromYmd(yyyyMmDd: string): string {
  return yyyyMmDd.slice(8, 10);
}

function defaultMonthly(yearMonth: string) {
  return {
    yearMonth,
    incomeMinorMain: 0,
    expenseMinorMain: 0,
    byCategoryMinorMain: {} as Record<string, number>,
    budgets: {},
    days: {} as Record<string, Record<string, unknown>>,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function mutDay(
  days: Record<string, Record<string, unknown>>,
  dd: string,
  field: "incomeMinorMain" | "expenseMinorMain",
  delta: number
) {
  if (!days[dd]) days[dd] = {};
  const cur = (days[dd][field] as number | undefined) ?? 0;
  days[dd][field] = cur + delta;
}

function toPayload(raw: DocumentData): TxPayload {
  return {
    transactionDate: raw.transactionDate as string,
    amountMinor: raw.amountMinor as number,
    direction: raw.direction as "in" | "out",
    currency: raw.currency as string,
    type: raw.type as string,
    accountId: raw.accountId as string,
    categoryId: raw.categoryId as string | undefined,
  };
}

export function txDataToPayload(data: DocumentData): TxPayload {
  return toPayload(data);
}

async function computeAmountMain(
  db: Firestore,
  mainCurrency: string,
  tx: TxPayload
): Promise<number> {
  const fx =
    tx.currency === mainCurrency
      ? null
      : await findForexDocWalkBack(db, tx.transactionDate);
  if (!fx && tx.currency !== mainCurrency) {
    throw new Error(
      `No forexRates doc within lookback for ${tx.transactionDate} (currency ${tx.currency})`
    );
  }
  return tx.currency === mainCurrency
    ? tx.amountMinor
    : foreignMinorToMainMinor(
        tx.amountMinor,
        tx.currency,
        mainCurrency,
        fx!.rates
      );
}

async function mutateLedgerInTransaction(
  t: FirebaseFirestore.Transaction,
  db: Firestore,
  uid: string,
  tx: TxPayload,
  sign: 1 | -1,
  amountMain: number
): Promise<void> {
  const isTransferLeg = tx.type === "transferLeg";
  const accountRef = db.doc(`users/${uid}/accounts/${tx.accountId}`);
  const accountSnap = await t.get(accountRef);
  if (!accountSnap.exists) {
    throw new Error(`Missing account ${tx.accountId}`);
  }
  const acc = accountSnap.data()!;
  const balMinor = (acc.balanceMinor as number) ?? 0;
  const balMain = (acc.balanceMinorMain as number | undefined) ?? 0;
  const dirSign = tx.direction === "in" ? 1 : -1;
  const balDelta = sign * dirSign * tx.amountMinor;
  const balMainDelta = sign * dirSign * amountMain;
  t.update(accountRef, {
    balanceMinor: balMinor + balDelta,
    balanceMinorMain: balMain + balMainDelta,
    updatedAt: FieldValue.serverTimestamp(),
  });

  if (isTransferLeg) {
    return;
  }

  const ym = monthKeyFromYmd(tx.transactionDate);
  const dd = dayKeyFromYmd(tx.transactionDate);
  const monthRef = db.doc(`users/${uid}/monthlyTotals/${ym}`);
  const monthSnap = await t.get(monthRef);
  const base = monthSnap.exists
    ? { ...(monthSnap.data() as Record<string, unknown>) }
    : defaultMonthly(ym);

  const income = (base.incomeMinorMain as number) ?? 0;
  const expense = (base.expenseMinorMain as number) ?? 0;
  const byCat =
    (base.byCategoryMinorMain as Record<string, number> | undefined) ?? {};
  const days =
    (base.days as Record<string, Record<string, unknown>> | undefined) ?? {};

  const flow =
    tx.direction === "in"
      ? { inc: amountMain, exp: 0 }
      : { inc: 0, exp: amountMain };

  base.incomeMinorMain = income + sign * flow.inc;
  base.expenseMinorMain = expense + sign * flow.exp;

  if (tx.categoryId) {
    const prev = byCat[tx.categoryId] ?? 0;
    const catDelta =
      tx.direction === "in" ? sign * amountMain : -sign * amountMain;
    byCat[tx.categoryId] = prev + catDelta;
  }
  base.byCategoryMinorMain = byCat;

  if (flow.inc) mutDay(days, dd, "incomeMinorMain", sign * flow.inc);
  if (flow.exp) mutDay(days, dd, "expenseMinorMain", sign * flow.exp);
  base.days = days;
  base.updatedAt = FieldValue.serverTimestamp();

  t.set(monthRef, base, { merge: true });
}

/**
 * One idempotent aggregate pass for create/delete.
 * `sign` +1 applies the row; -1 reverses it.
 */
export async function runLedgerAggregate(
  db: Firestore,
  uid: string,
  eventId: string,
  tx: TxPayload,
  sign: 1 | -1
): Promise<void> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const mainCurrency = (userSnap.data()?.mainCurrency as string) ?? "MXN";
  const amountMain = await computeAmountMain(db, mainCurrency, tx);

  await db.runTransaction(async (t) => {
    const idemRef = db.doc(`users/${uid}/_processedAggregateEvents/${eventId}`);
    if ((await t.get(idemRef)).exists) return;
    t.create(idemRef, { createdAt: FieldValue.serverTimestamp() });
    await mutateLedgerInTransaction(t, db, uid, tx, sign, amountMain);
  });
}

/** Replace `beforeTx` with `afterTx` under a single idempotency key (document updates). */
export async function runLedgerAggregateUpdate(
  db: Firestore,
  uid: string,
  eventId: string,
  beforeTx: TxPayload,
  afterTx: TxPayload
): Promise<void> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const mainCurrency = (userSnap.data()?.mainCurrency as string) ?? "MXN";
  const beforeMain = await computeAmountMain(db, mainCurrency, beforeTx);
  const afterMain = await computeAmountMain(db, mainCurrency, afterTx);

  await db.runTransaction(async (t) => {
    const idemRef = db.doc(`users/${uid}/_processedAggregateEvents/${eventId}`);
    if ((await t.get(idemRef)).exists) return;
    t.create(idemRef, { createdAt: FieldValue.serverTimestamp() });
    await mutateLedgerInTransaction(t, db, uid, beforeTx, -1, beforeMain);
    await mutateLedgerInTransaction(t, db, uid, afterTx, 1, afterMain);
  });
}
