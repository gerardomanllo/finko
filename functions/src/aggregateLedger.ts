import type { DocumentData, DocumentReference, Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
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

/** Ignore these keys when deciding if a transaction write should skip the ledger trigger. */
const SKIP_TRIGGER_COMPARE_KEYS = new Set([
  "amountMinorMain",
  "fxRateDateUsed",
  "updatedAt",
  /** Written by aggregate after a successful apply; must not re-trigger aggregation. */
  "aggregateApplied",
  /** Client-only flags used to re-run catch-up aggregation. */
  "reload",
  "aggregateReload",
]);

const FINANCIAL_COMPARE_KEYS = [
  "transactionDate",
  "amountMinor",
  "direction",
  "currency",
  "type",
  "accountId",
  "categoryId",
] as const;

function normField(v: unknown): unknown {
  if (v === undefined) return null;
  return v;
}

/** True when ledger-relevant fields are identical (reload / memo-only edits). */
export function isFinancialUnchanged(
  before: Record<string, unknown>,
  after: Record<string, unknown>
): boolean {
  return FINANCIAL_COMPARE_KEYS.every(
    (k) => JSON.stringify(normField(before[k])) === JSON.stringify(normField(after[k]))
  );
}

function coerceFiniteInt(value: unknown, field: string): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  if (typeof value === "string" && value.trim() !== "") {
    const n = Number(value.trim().replace(/,/g, ""));
    if (Number.isFinite(n)) return Math.trunc(n);
  }
  if (value != null && typeof value === "object" && "valueOf" in value) {
    const n = Number((value as { valueOf(): unknown }).valueOf());
    if (Number.isFinite(n)) return Math.trunc(n);
  }
  logger.warn(`aggregateLedger: coerced missing/non-numeric ${field} to 0`, { field });
  return 0;
}

function normalizeDirection(raw: unknown): "in" | "out" {
  const s = typeof raw === "string" ? raw.trim().toLowerCase() : "";
  if (s === "in") return "in";
  if (s === "out") return "out";
  logger.warn("aggregateLedger: unknown direction, defaulting to out", { raw });
  return "out";
}

/** Skip aggregate work when only audit / meta fields changed. */
export function isAuditOnlyTransactionUpdate(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined
): boolean {
  if (!before || !after) return false;
  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  for (const k of keys) {
    if (SKIP_TRIGGER_COMPARE_KEYS.has(k)) continue;
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

function ensureDay(days: Record<string, Record<string, unknown>>, dd: string) {
  if (!days[dd]) days[dd] = {};
}

function netWorthAt(
  days: Record<string, Record<string, unknown>>,
  dd: string
): number | undefined {
  const value = days[dd]?.netWorthEodMinorMain;
  return typeof value === "number" ? value : undefined;
}

function setNetWorth(
  days: Record<string, Record<string, unknown>>,
  dd: string,
  value: number
) {
  ensureDay(days, dd);
  days[dd].netWorthEodMinorMain = value;
}

/**
 * Applies a net-worth delta to day `dd` and carries it forward through any
 * existing later day points in the same month.
 */
function applyNetWorthDelta(
  days: Record<string, Record<string, unknown>>,
  dd: string,
  delta: number
) {
  const sortedKeys = Object.keys(days)
    .filter((k) => /^\d{2}$/.test(k))
    .sort((a, b) => a.localeCompare(b));
  const prev = [...sortedKeys].reverse().find((k) => k < dd);
  const base = prev ? (netWorthAt(days, prev) ?? 0) : 0;
  const current = netWorthAt(days, dd) ?? base;
  setNetWorth(days, dd, current + delta);

  for (const key of sortedKeys) {
    if (key <= dd) continue;
    const value = netWorthAt(days, key);
    if (value == null) continue;
    setNetWorth(days, key, value + delta);
  }
}

function toPayload(raw: DocumentData): TxPayload {
  const amountMinor = coerceFiniteInt(raw.amountMinor, "amountMinor");
  const direction = normalizeDirection(raw.direction);
  if (amountMinor === 0 && direction === "in") {
    logger.warn("aggregateLedger: amountMinor is 0 for inflow tx", {
      transactionDate: raw.transactionDate,
      type: raw.type,
    });
  }
  return {
    transactionDate: String(raw.transactionDate ?? ""),
    amountMinor,
    direction,
    currency: typeof raw.currency === "string" && raw.currency.trim() ? raw.currency.trim() : "MXN",
    type: typeof raw.type === "string" && raw.type ? raw.type : "standard",
    accountId: typeof raw.accountId === "string" ? raw.accountId : "",
    categoryId:
      typeof raw.categoryId === "string" && raw.categoryId.trim().length > 0
        ? raw.categoryId.trim()
        : undefined,
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
  const main =
    tx.currency === mainCurrency
      ? tx.amountMinor
      : foreignMinorToMainMinor(
          tx.amountMinor,
          tx.currency,
          mainCurrency,
          fx!.rates
        );
  if (!Number.isFinite(main)) {
    throw new Error(`Non-finite amountMain for tx on ${tx.transactionDate}`);
  }
  return main;
}

type AggregateOp = {
  tx: TxPayload;
  sign: 1 | -1;
  amountMain: number;
};

function applyMonthDelta(
  base: Record<string, unknown>,
  tx: TxPayload,
  sign: 1 | -1,
  amountMain: number
): void {
  const dd = dayKeyFromYmd(tx.transactionDate);
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
  const netWorthDelta = sign * (tx.direction === "in" ? amountMain : -amountMain);

  base.incomeMinorMain = income + sign * flow.inc;
  base.expenseMinorMain = expense + sign * flow.exp;

  if (tx.categoryId) {
    const prev = byCat[tx.categoryId] ?? 0;
    const catDelta = tx.direction === "in" ? sign * amountMain : -sign * amountMain;
    byCat[tx.categoryId] = prev + catDelta;
  }
  base.byCategoryMinorMain = byCat;

  if (flow.inc !== 0 && Number.isFinite(flow.inc)) {
    mutDay(days, dd, "incomeMinorMain", sign * flow.inc);
  }
  if (flow.exp !== 0 && Number.isFinite(flow.exp)) {
    mutDay(days, dd, "expenseMinorMain", sign * flow.exp);
  }
  applyNetWorthDelta(days, dd, netWorthDelta);
  base.days = days;
  base.updatedAt = FieldValue.serverTimestamp();
}

async function runAggregateOpsTransaction(
  db: Firestore,
  uid: string,
  eventId: string,
  ops: AggregateOp[],
  ledgerTxRef?: DocumentReference
): Promise<void> {
  await db.runTransaction(async (t) => {
    const idemRef = db.doc(`users/${uid}/_processedAggregateEvents/${eventId}`);
    const accountRefs = new Map<string, FirebaseFirestore.DocumentReference>();
    const monthRefs = new Map<string, FirebaseFirestore.DocumentReference>();

    for (const op of ops) {
      const { tx } = op;
      if (!accountRefs.has(tx.accountId)) {
        accountRefs.set(tx.accountId, db.doc(`users/${uid}/accounts/${tx.accountId}`));
      }
      if (tx.type !== "transferLeg") {
        const ym = monthKeyFromYmd(tx.transactionDate);
        if (!monthRefs.has(ym)) {
          monthRefs.set(ym, db.doc(`users/${uid}/monthlyTotals/${ym}`));
        }
      }
    }

    const readRefs: FirebaseFirestore.DocumentReference[] = [
      idemRef,
      ...accountRefs.values(),
      ...monthRefs.values(),
    ];
    const readSnaps = await t.getAll(...readRefs);
    const [idemSnap, ...entitySnaps] = readSnaps;
    if (idemSnap.exists) return;

    const accountData = new Map<
      string,
      { ref: FirebaseFirestore.DocumentReference; balanceMinor: number; balanceMinorMain: number }
    >();
    const monthData = new Map<string, { ref: FirebaseFirestore.DocumentReference; base: Record<string, unknown> }>();

    let idx = 0;
    for (const [accountId, ref] of accountRefs) {
      const snap = entitySnaps[idx++];
      if (!snap.exists) {
        throw new Error(`Missing account ${accountId}`);
      }
      const data = snap.data()!;
      accountData.set(accountId, {
        ref,
        balanceMinor: (data.balanceMinor as number) ?? 0,
        balanceMinorMain: (data.balanceMinorMain as number | undefined) ?? 0,
      });
    }

    for (const [ym, ref] of monthRefs) {
      const snap = entitySnaps[idx++];
      const base = snap.exists
        ? { ...(snap.data() as Record<string, unknown>) }
        : defaultMonthly(ym);
      monthData.set(ym, { ref, base });
    }

    for (const op of ops) {
      const { tx, sign, amountMain } = op;
      const dirSign = tx.direction === "in" ? 1 : -1;
      const account = accountData.get(tx.accountId)!;
      account.balanceMinor += sign * dirSign * tx.amountMinor;
      account.balanceMinorMain += sign * dirSign * amountMain;

      if (tx.type !== "transferLeg") {
        const ym = monthKeyFromYmd(tx.transactionDate);
        const month = monthData.get(ym)!;
        applyMonthDelta(month.base, tx, sign, amountMain);
      }
    }

    t.create(idemRef, { createdAt: FieldValue.serverTimestamp() });
    for (const { ref, balanceMinor, balanceMinorMain } of accountData.values()) {
      t.update(ref, {
        balanceMinor,
        balanceMinorMain,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    for (const { ref, base } of monthData.values()) {
      t.set(ref, base, { merge: true });
    }

    if (ledgerTxRef) {
      t.set(
        ledgerTxRef,
        {
          aggregateApplied: true,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  });
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
  sign: 1 | -1,
  ledgerTxRef?: DocumentReference
): Promise<void> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const mainCurrency = (userSnap.data()?.mainCurrency as string) ?? "MXN";
  const amountMain = await computeAmountMain(db, mainCurrency, tx);
  await runAggregateOpsTransaction(
    db,
    uid,
    eventId,
    [{ tx, sign, amountMain }],
    sign === 1 ? ledgerTxRef : undefined
  );
}

/** Replace `beforeTx` with `afterTx` under a single idempotency key (document updates). */
export async function runLedgerAggregateUpdate(
  db: Firestore,
  uid: string,
  eventId: string,
  beforeTx: TxPayload,
  afterTx: TxPayload,
  ledgerTxRef?: DocumentReference
): Promise<void> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const mainCurrency = (userSnap.data()?.mainCurrency as string) ?? "MXN";
  const beforeMain = await computeAmountMain(db, mainCurrency, beforeTx);
  const afterMain = await computeAmountMain(db, mainCurrency, afterTx);
  await runAggregateOpsTransaction(
    db,
    uid,
    eventId,
    [
      { tx: beforeTx, sign: -1, amountMain: beforeMain },
      { tx: afterTx, sign: 1, amountMain: afterMain },
    ],
    ledgerTxRef
  );
}
