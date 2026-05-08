import { formatLedgerAmountMinor } from "../../src/telegram/telegramAmountFormat";

describe("formatLedgerAmountMinor", () => {
  it("formats MXN with thousands separator and $ prefix", () => {
    expect(formatLedgerAmountMinor(123456789, "mxn")).toBe("MXN $1,234,567.89");
  });

  it("defaults missing currency to MXN", () => {
    expect(formatLedgerAmountMinor(1000, "")).toBe("MXN $10.00");
  });

  it("formats USD", () => {
    expect(formatLedgerAmountMinor(999, "USD")).toBe("USD $9.99");
  });
});
