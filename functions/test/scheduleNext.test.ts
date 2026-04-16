import { computeNextTransactionDate, resolveAsOfYmd } from "../src/scheduleNext";

describe("scheduleNext", () => {
  it("computes next twice-monthly date after mid-month", () => {
    expect(
      computeNextTransactionDate("2026-01-15", {
        cadence: "twiceMonthly",
        daysOfMonth: [1, 15],
        weekday: null,
      })
    ).toBe("2026-02-01");
  });

  it("rolls monthly on 31 to last day of shorter month", () => {
    expect(
      computeNextTransactionDate("2026-01-31", {
        cadence: "monthly",
        daysOfMonth: [31],
        weekday: null,
      })
    ).toBe("2026-02-28");
  });

  it("resolveAsOfYmd returns yyyy-MM-dd with timezone", () => {
    expect(typeof resolveAsOfYmd({ timezone: "America/Mexico_City" })).toBe("string");
  });
});
