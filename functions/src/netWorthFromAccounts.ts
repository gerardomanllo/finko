/**
 * Net worth as signed sum of account balances in main currency (matches Flutter
 * `signedBalanceForNetWorthMinor` / `netWorthFromAccountsMinor`).
 */

import type { BalancePolarity } from "./ledgerAggregateMath";

/** In-memory aggregate account row (same shape as `runAggregateOpsTransaction`). */
export type AccountNwState = {
  balanceMinor: number;
  balanceMinorMain: number;
  balancePolarity: BalancePolarity;
};

export function signedNetWorthContributionMain(state: AccountNwState): number {
  const b = state.balanceMinorMain;
  const main = typeof b === "number" && Number.isFinite(b) ? Math.trunc(b) : 0;
  return state.balancePolarity === "liability" ? -main : main;
}

export function sumNetWorthMinorMainFromAccountStates(
  states: Iterable<AccountNwState>
): number {
  let sum = 0;
  for (const s of states) {
    sum += signedNetWorthContributionMain(s);
  }
  return sum;
}
