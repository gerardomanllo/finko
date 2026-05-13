/**
 * Pure ledger aggregation math (no Firestore / FieldValue).
 * Used by aggregateLedger.ts and Jest tests.
 */

export type TxPayload = {
  transactionDate: string;
  amountMinor: number;
  direction: "in" | "out";
  currency: string;
  type: string;
  accountId: string;
  categoryId?: string;
};

export type AggregateOp = {
  tx: TxPayload;
  sign: 1 | -1;
  amountMain: number;
};

export function monthKeyFromYmd(yyyyMmDd: string): string {
  return yyyyMmDd.slice(0, 7);
}

export function dayKeyFromYmd(yyyyMmDd: string): string {
  return yyyyMmDd.slice(8, 10);
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

/**
 * Mutates `base` (a monthlyTotals document body) for one signed operation.
 * Does not set `updatedAt` — caller adds FieldValue when writing to Firestore.
 */
export function applyMonthDelta(
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
  base.days = days;
}

/** Asset: positive balance = money held. Liability: positive balance = amount owed. */
export type BalancePolarity = "asset" | "liability";

export type AccountBalanceState = {
  balanceMinor: number;
  balanceMinorMain: number;
};

/**
 * Applies one aggregate op to account balances (same rules as runAggregateOpsTransaction).
 * [balancePolarity] inverts the direction effect for liabilities so `out` increases owed.
 */
export function applyAccountDelta(
  account: AccountBalanceState,
  tx: TxPayload,
  sign: 1 | -1,
  amountMain: number,
  balancePolarity: BalancePolarity = "asset"
): void {
  const dirSign = tx.direction === "in" ? 1 : -1;
  const m = balancePolarity === "liability" ? -1 : 1;
  account.balanceMinor += sign * m * dirSign * tx.amountMinor;
  account.balanceMinorMain += sign * m * dirSign * amountMain;
}

/**
 * Builds −before / +after ops for `runLedgerAggregateUpdate` (money fields already converted to main).
 */
export function computeLedgerUpdateOps(
  beforeIn: boolean,
  afterIn: boolean,
  beforeMoneyIncluded: boolean,
  beforeTx: TxPayload,
  afterTx: TxPayload,
  beforeMain: number,
  afterMain: number
): AggregateOp[] {
  const ops: AggregateOp[] = [];
  if (beforeIn && beforeMoneyIncluded) {
    ops.push({ tx: beforeTx, sign: -1, amountMain: beforeMain });
  }
  if (afterIn) {
    ops.push({ tx: afterTx, sign: 1, amountMain: afterMain });
  }
  return ops;
}
