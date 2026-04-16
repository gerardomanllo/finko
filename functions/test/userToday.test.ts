import { getUserTodayYmd, isLedgerDateEffectiveForAggregate } from "../src/userToday";

describe("userToday", () => {
  describe("isLedgerDateEffectiveForAggregate", () => {
    it("includes past and same-day posting dates vs today", () => {
      expect(isLedgerDateEffectiveForAggregate("2026-01-01", "2026-06-01")).toBe(true);
      expect(isLedgerDateEffectiveForAggregate("2026-06-01", "2026-06-01")).toBe(true);
    });

    it("excludes strictly future posting dates", () => {
      expect(isLedgerDateEffectiveForAggregate("2026-12-31", "2026-06-01")).toBe(false);
    });

    it("fail-open for malformed date strings (include in aggregates)", () => {
      expect(isLedgerDateEffectiveForAggregate("not-a-date", "2026-06-01")).toBe(true);
      expect(isLedgerDateEffectiveForAggregate("", "2026-06-01")).toBe(true);
    });
  });

  describe("getUserTodayYmd", () => {
    it("returns an ISO yyyy-MM-dd for UTC profile", () => {
      expect(getUserTodayYmd({ timezone: "UTC" })).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });
  });
});
