import type { AggregateOp } from "../../src/ledgerAggregateMath";
import {
  applyAccountDelta,
  applyMonthDelta,
  monthKeyFromYmd,
} from "../../src/ledgerAggregateMath";

export type AccountMap = Record<string, { balanceMinor: number; balanceMinorMain: number }>;
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
    applyAccountDelta(acc, op.tx, op.sign, op.amountMain);

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
