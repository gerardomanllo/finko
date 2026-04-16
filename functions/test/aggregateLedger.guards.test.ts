import {
  isAuditOnlyTransactionUpdate,
  isFinancialUnchanged,
  snapshotBalancesIncludedThisRow,
  txDataToPayload,
} from "../src/aggregateLedger";

describe("aggregateLedger guards", () => {
  describe("snapshotBalancesIncludedThisRow", () => {
    it("treats aggregateApplied true as included", () => {
      expect(snapshotBalancesIncludedThisRow({ aggregateApplied: true })).toBe(true);
    });

    it("excludes when aggregateApplied is explicitly false", () => {
      expect(snapshotBalancesIncludedThisRow({ aggregateApplied: false })).toBe(false);
    });

    it("excludes deferred rows even if aggregateApplied is true", () => {
      expect(
        snapshotBalancesIncludedThisRow({ aggregateDeferred: true, aggregateApplied: true })
      ).toBe(false);
    });

    it("treats legacy rows (omit aggregateApplied) as included", () => {
      expect(snapshotBalancesIncludedThisRow({})).toBe(true);
    });
  });

  describe("isFinancialUnchanged", () => {
    it("detects identical financial fields", () => {
      const row = {
        transactionDate: "2026-04-10",
        amountMinor: 100,
        direction: "out",
        currency: "MXN",
        type: "standard",
        accountId: "a1",
        categoryId: "c1",
      };
      expect(isFinancialUnchanged(row, { ...row })).toBe(true);
    });

    it("detects amount change", () => {
      const a = {
        transactionDate: "2026-04-10",
        amountMinor: 100,
        direction: "out",
        currency: "MXN",
        type: "standard",
        accountId: "a1",
      };
      expect(isFinancialUnchanged(a, { ...a, amountMinor: 200 })).toBe(false);
    });
  });

  describe("isAuditOnlyTransactionUpdate", () => {
    it("returns false when memo changes", () => {
      expect(
        isAuditOnlyTransactionUpdate(
          { memo: "a", amountMinor: 1 },
          { memo: "b", amountMinor: 1 }
        )
      ).toBe(false);
    });

    it("returns true when only skip-list fields differ", () => {
      expect(
        isAuditOnlyTransactionUpdate(
          { amountMinor: 100, aggregateApplied: false },
          { amountMinor: 100, aggregateApplied: true }
        )
      ).toBe(true);
    });
  });

  describe("txDataToPayload", () => {
    it("coerces amount and defaults direction unknown to out", () => {
      const p = txDataToPayload({
        transactionDate: "2026-04-10",
        amountMinor: "5000",
        direction: "OUT",
        currency: "MXN",
        type: "standard",
        accountId: "a1",
      });
      expect(p.amountMinor).toBe(5000);
      expect(p.direction).toBe("out");
    });
  });
});
