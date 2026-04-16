import type { DocumentData, DocumentReference, Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { findForexDocWalkBack, foreignMinorToMainMinor } from "./forex";
import {
  applyAccountDelta,
  applyMonthDelta as applyMonthDeltaPure,
  computeLedgerUpdateOps,
  monthKeyFromYmd,
  type AggregateOp,
  type TxPayload,
} from "./ledgerAggregateMath";
import { getUserTodayYmd, isLedgerDateEffectiveForAggregate } from "./userToday";

export type { TxPayload } from "./ledgerAggregateMath";

/** Ignore these keys when deciding if a transaction write should skip the ledger trigger. */
const SKIP_TRIGGER_COMPARE_KEYS = new Set([
  "amountMinorMain",
  "fxRateDateUsed",
  "updatedAt",
  /** Written by aggregate after a successful apply; must not re-trigger aggregation. */
  "aggregateApplied",
  /** Server-owned: future-dated row pending inclusion in balances (see `reconcileDeferredLedgerForUser`). */
  "aggregateDeferred",
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

/**
 * True if this ledger row’s amounts should already be reflected in **`accounts`** /
 * **`monthlyTotals`** (so delete / −before may reverse them).
 *
 * - **`aggregateDeferred: true`** — never applied (future-dated path); do not reverse money.
 * - **`aggregateApplied: false`** — Functions did not finish applying; do not reverse (avoids
 *   corrupting **`accounts`** when **`monthlyTotals`** never got the +1 either).
 * - **`aggregateApplied: true`** or **omitted** (legacy) — treat as applied for reversal.
 */
export function snapshotBalancesIncludedThisRow(data: Record<string, unknown>): boolean {
  if (data["aggregateDeferred"] === true) {
    return false;
  }
  if (data["aggregateApplied"] === false) {
    return false;
  }
  return true;
}

/** Pass the Firestore `before` snapshot for deletes and updates so reversals match reality. */
export type LedgerAggregateSourceOptions = {
  beforeLedgerSnapshot?: Record<string, unknown>;
};

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
      const account = accountData.get(tx.accountId)!;
      applyAccountDelta(account, tx, sign, amountMain);

      if (tx.type !== "transferLeg") {
        const ym = monthKeyFromYmd(tx.transactionDate);
        const month = monthData.get(ym)!;
        applyMonthDeltaPure(month.base, tx, sign, amountMain);
        month.base.updatedAt = FieldValue.serverTimestamp();
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
          aggregateDeferred: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  });
}

/**
 * Future-dated row: no balance/monthly changes yet; record idempotency and
 * `aggregateDeferred` so a scheduled job can apply when the posting date arrives.
 */
async function markLedgerDeferredNoMoney(
  db: Firestore,
  uid: string,
  eventId: string,
  ledgerTxRef?: DocumentReference
): Promise<void> {
  await db.runTransaction(async (t) => {
    const idemRef = db.doc(`users/${uid}/_processedAggregateEvents/${eventId}`);
    const idemSnap = await t.get(idemRef);
    if (idemSnap.exists) {
      return;
    }
    t.create(idemRef, { createdAt: FieldValue.serverTimestamp() });
    if (ledgerTxRef) {
      t.set(
        ledgerTxRef,
        {
          aggregateApplied: true,
          aggregateDeferred: true,
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
 *
 * Rows with `transactionDate` **after** the user’s calendar today (`users/{uid}.timezone`,
 * else system default) do not change balances or `monthlyTotals`; idempotency is still recorded.
 */
export async function runLedgerAggregate(
  db: Firestore,
  uid: string,
  eventId: string,
  tx: TxPayload,
  sign: 1 | -1,
  ledgerTxRef?: DocumentReference,
  sourceOpts?: LedgerAggregateSourceOptions
): Promise<void> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const userData = userSnap.data() as Record<string, unknown> | undefined;
  const mainCurrency = (userData?.mainCurrency as string) ?? "MXN";
  const todayYmd = getUserTodayYmd(userData);

  // Delete: only reverse money if the row was actually applied to balances/monthly.
  if (sign === -1 && sourceOpts?.beforeLedgerSnapshot) {
    if (!snapshotBalancesIncludedThisRow(sourceOpts.beforeLedgerSnapshot)) {
      await markLedgerDeferredNoMoney(db, uid, eventId);
      return;
    }
  }

  if (!isLedgerDateEffectiveForAggregate(tx.transactionDate, todayYmd)) {
    await markLedgerDeferredNoMoney(db, uid, eventId, ledgerTxRef);
    return;
  }

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
  ledgerTxRef?: DocumentReference,
  sourceOpts?: LedgerAggregateSourceOptions
): Promise<void> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const userData = userSnap.data() as Record<string, unknown> | undefined;
  const mainCurrency = (userData?.mainCurrency as string) ?? "MXN";
  const todayYmd = getUserTodayYmd(userData);

  const beforeIn = isLedgerDateEffectiveForAggregate(beforeTx.transactionDate, todayYmd);
  const afterIn = isLedgerDateEffectiveForAggregate(afterTx.transactionDate, todayYmd);

  const beforeMain = await computeAmountMain(db, mainCurrency, beforeTx);
  const afterMain = await computeAmountMain(db, mainCurrency, afterTx);

  const beforeSnap = sourceOpts?.beforeLedgerSnapshot;
  const beforeMoneyIncluded =
      beforeSnap == null || snapshotBalancesIncludedThisRow(beforeSnap);

  const ops = computeLedgerUpdateOps(
    beforeIn,
    afterIn,
    beforeMoneyIncluded,
    beforeTx,
    afterTx,
    beforeMain,
    afterMain
  );

  if (ops.length === 0) {
    await markLedgerDeferredNoMoney(db, uid, eventId, ledgerTxRef);
    return;
  }

  await runAggregateOpsTransaction(db, uid, eventId, ops, ledgerTxRef);

  if (ledgerTxRef && !afterIn) {
    await ledgerTxRef.set(
      {
        aggregateApplied: true,
        aggregateDeferred: true,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
}
