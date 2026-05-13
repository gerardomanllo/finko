import { sumNetWorthMinorMainFromAccountStates, signedNetWorthContributionMain } from "../src/netWorthFromAccounts";
import type { AccountNwState } from "../src/netWorthFromAccounts";

describe("netWorthFromAccounts", () => {
  it("sums assets and subtracts liabilities", () => {
    const states: AccountNwState[] = [
      { balanceMinorMain: 1_000_000, balanceMinor: 1_000_000, balancePolarity: "asset" },
      { balanceMinorMain: 500_000, balanceMinor: 500_000, balancePolarity: "asset" },
      { balanceMinorMain: 20_000, balanceMinor: 20_000, balancePolarity: "liability" },
    ];
    expect(sumNetWorthMinorMainFromAccountStates(states)).toBe(1_000_000 + 500_000 - 20_000);
  });

  it("treats non-finite balanceMinorMain as 0", () => {
    const s: AccountNwState = {
      balanceMinorMain: NaN,
      balanceMinor: 100,
      balancePolarity: "asset",
    };
    expect(signedNetWorthContributionMain(s)).toBe(0);
  });
});
