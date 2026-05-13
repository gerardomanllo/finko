import { computeLedgerUpdateOps } from "../src/ledgerAggregateMath";
import type { TxPayload } from "../src/ledgerAggregateMath";
import {
  ACC,
  CAT,
  CURRENCY_MXN,
  initialAccounts,
  initialMonths,
} from "./fixtures/ledgerWorld";
import { simulateAggregateOps } from "./helpers/simulateAggregateOps";

describe("simulateAggregateOps net worth snapshots", () => {
  const stdExpense = (d: string, amount: number, accountId: string): TxPayload => ({
    transactionDate: d,
    amountMinor: amount,
    direction: "out",
    currency: CURRENCY_MXN,
    type: "standard",
    accountId,
    categoryId: CAT.food,
  });

  it("writes distinct NW snapshots for −before and +after on different dates", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const before = stdExpense("2026-03-20", 8_000, ACC.checking);
    const after = stdExpense("2026-04-05", 8_000, ACC.checking);

    simulateAggregateOps([{ tx: before, sign: 1, amountMain: 8_000 }], accounts, months);
    const ops = computeLedgerUpdateOps(true, true, true, before, after, 8_000, 8_000);
    simulateAggregateOps(ops, accounts, months);

    const d03 = months["2026-03"].days as Record<string, Record<string, unknown>>;
    const d04 = months["2026-04"].days as Record<string, Record<string, unknown>>;
    expect(d03["20"]?.netWorthEodMinorMain).toBe(2_000_000);
    expect(d04["05"]?.netWorthEodMinorMain).toBe(1_992_000);
  });
});
