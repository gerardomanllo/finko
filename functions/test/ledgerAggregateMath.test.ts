import {
  applyAccountDelta,
  applyMonthDelta,
  computeLedgerUpdateOps,
  monthKeyFromYmd,
  type TxPayload,
} from "../src/ledgerAggregateMath";
import { emptyMonthBody } from "./fixtures/ledgerWorld";

describe("ledgerAggregateMath", () => {
  const baseTx = (over: Partial<TxPayload>): TxPayload => ({
    transactionDate: "2026-04-10",
    amountMinor: 5000,
    direction: "out",
    currency: "MXN",
    type: "standard",
    accountId: "a1",
    categoryId: "c1",
    ...over,
  });

  describe("monthKeyFromYmd", () => {
    it("extracts yyyy-mm", () => {
      expect(monthKeyFromYmd("2026-03-31")).toBe("2026-03");
    });
  });

  describe("applyMonthDelta", () => {
    it("increments expense and day bucket for an outflow", () => {
      const base = emptyMonthBody("2026-04");
      applyMonthDelta(base, baseTx({}), 1, 5000);
      expect(base.expenseMinorMain).toBe(5000);
      expect(base.incomeMinorMain).toBe(0);
      expect((base.byCategoryMinorMain as Record<string, number>)["c1"]).toBe(-5000);
      const days = base.days as Record<string, Record<string, unknown>>;
      expect(days["10"]?.expenseMinorMain).toBe(5000);
    });

    it("increments income and category net for inflow", () => {
      const base = emptyMonthBody("2026-04");
      applyMonthDelta(
        base,
        baseTx({ direction: "in", categoryId: "c1" }),
        1,
        10_000
      );
      expect(base.incomeMinorMain).toBe(10_000);
      expect((base.byCategoryMinorMain as Record<string, number>)["c1"]).toBe(10_000);
    });
  });

  describe("applyAccountDelta", () => {
    it("decreases balance on outflow apply", () => {
      const acc = { balanceMinor: 100_000, balanceMinorMain: 100_000 };
      applyAccountDelta(acc, baseTx({ amountMinor: 5000 }), 1, 5000);
      expect(acc.balanceMinor).toBe(95_000);
      expect(acc.balanceMinorMain).toBe(95_000);
    });
  });

  describe("computeLedgerUpdateOps", () => {
    it("builds −before only when moving effective date to future", () => {
      const before = baseTx({ transactionDate: "2026-04-10" });
      const after = baseTx({ transactionDate: "2026-05-01" });
      const ops = computeLedgerUpdateOps(
        true,
        false,
        true,
        before,
        after,
        5000,
        5000
      );
      expect(ops).toEqual([{ tx: before, sign: -1, amountMain: 5000 }]);
    });

    it("builds +after only when before was not in balances (e.g. deferred)", () => {
      const before = baseTx({ transactionDate: "2026-05-01" });
      const after = baseTx({ transactionDate: "2026-04-10" });
      const ops = computeLedgerUpdateOps(
        false,
        true,
        false,
        before,
        after,
        5000,
        5000
      );
      expect(ops).toEqual([{ tx: after, sign: 1, amountMain: 5000 }]);
    });

    it("builds −before and +after for same-day amount change", () => {
      const before = baseTx({ amountMinor: 100 });
      const after = baseTx({ amountMinor: 200 });
      const ops = computeLedgerUpdateOps(true, true, true, before, after, 100, 200);
      expect(ops).toEqual([
        { tx: before, sign: -1, amountMain: 100 },
        { tx: after, sign: 1, amountMain: 200 },
      ]);
    });
  });
});
