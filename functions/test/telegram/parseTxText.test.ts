import {
  parseAmountMinorFromFollowUp,
  parseSpendLine,
  suggestsConversationalParse,
} from "../../src/telegram/parseTxText";

describe("parseTxText helpers", () => {
  it("parseAmountMinorFromFollowUp accepts heuristic lines and plain numbers", () => {
    expect(parseAmountMinorFromFollowUp("MXN", "12.50")).toBe(1250);
    expect(parseAmountMinorFromFollowUp("MXN", "100")).toBe(10000);
    expect(parseAmountMinorFromFollowUp("MXN", "+25")).toBe(2500);
    expect(parseAmountMinorFromFollowUp("MXN", "abc")).toBeNull();
  });

  it("suggestsConversationalParse is true for multi-word non-amount-first Spanish", () => {
    expect(suggestsConversationalParse("gasté 100 pesos en el super")).toBe(true);
    expect(suggestsConversationalParse("50 coffee")).toBe(false);
  });

  it("parseSpendLine still matches amount-first patterns", () => {
    expect(parseSpendLine("MXN", "50 coffee")?.amountMinor).toBe(5000);
  });
});
