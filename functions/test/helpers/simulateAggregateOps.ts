import type { AggregateOp, BalancePolarity } from "../../src/ledgerAggregateMath";
import {
  applyAccountDelta,
  applyMonthDelta,
  monthKeyFromYmd,
} from "../../src/ledgerAggregateMath";

export type AccountMapEntry = {
  balanceMinor: number;
  balanceMinorMain: number;
  /** Default `asset`. */
  balancePolarity?: BalancePolarity;
};

export type AccountMap = Record<string, AccountMapEntry>;
export type MonthMap = Record<string, Record<string, unknown>>;

/**
 * In-memory equivalent of the inner loop in `runAggregateOpsTransaction`
 * (no Firestore, no idempotency).
 */
export function simulateAggregateOps(
  ops: AggregateOp[],
  accounts: AccountMap,
  months: MonthMap
): void {
  for (const op of ops) {
    const acc = accounts[op.tx.accountId];
    if (!acc) {
      throw new Error(`Unknown account ${op.tx.accountId}`);
    }
    applyAccountDelta(
      acc,
      op.tx,
      op.sign,
      op.amountMain,
      acc.balancePolarity ?? "asset"
    );

    if (op.tx.type !== "transferLeg") {
      const ym = monthKeyFromYmd(op.tx.transactionDate);
      const base = months[ym];
      if (!base) {
        throw new Error(`Unknown month ${ym}`);
      }
      applyMonthDelta(base, op.tx, op.sign, op.amountMain);
    }
  }
}
