import type { AggregateOp, BalancePolarity } from "../../src/ledgerAggregateMath";
import {
  applyAccountDelta,
  applyMonthDelta,
  dayKeyFromYmd,
  monthKeyFromYmd,
} from "../../src/ledgerAggregateMath";
import { sumNetWorthMinorMainFromAccountStates } from "../../src/netWorthFromAccounts";

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

    const ym = monthKeyFromYmd(op.tx.transactionDate);
    const base = months[ym];
    if (!base) {
      throw new Error(`Unknown month ${ym}`);
    }
    const nwStates = Object.values(accounts).map((a) => ({
      balanceMinor: a.balanceMinor,
      balanceMinorMain: a.balanceMinorMain,
      balancePolarity: (a.balancePolarity ?? "asset") as BalancePolarity,
    }));
    const nw = sumNetWorthMinorMainFromAccountStates(nwStates);
    const days =
      (base.days as Record<string, Record<string, unknown>> | undefined) ?? {};
    const dd = dayKeyFromYmd(op.tx.transactionDate);
    const dayObj = { ...(days[dd] ?? {}) };
    dayObj.netWorthEodMinorMain = nw;
    const nextDays = { ...days, [dd]: dayObj };
    base.days = nextDays;

    if (op.tx.type !== "transferLeg") {
      applyMonthDelta(base, op.tx, op.sign, op.amountMain);
    }
  }
}
