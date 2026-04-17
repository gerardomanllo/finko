/**
 * Fixed mock world for ledger aggregation Jest tests (deterministic dates and IDs).
 */

export const USER_TODAY_YMD = "2026-04-15";

/** Account document ids */
export const ACC = {
  checking: "acc_checking",
  savings: "acc_savings",
} as const;

/** Category ids */
export const CAT = {
  food: "cat_food",
  salary: "cat_salary",
} as const;

export const CURRENCY_MXN = "MXN";

export function emptyMonthBody(yearMonth: string): Record<string, unknown> {
  return {
    yearMonth,
    incomeMinorMain: 0,
    expenseMinorMain: 0,
    byCategoryMinorMain: {} as Record<string, number>,
    days: {} as Record<string, Record<string, unknown>>,
  };
}

/** Starting balances: 1,000,000 minor units each (same currency as main). */
export function initialAccounts(): Record<
  string,
  { balanceMinor: number; balanceMinorMain: number }
> {
  const bal = 1_000_000;
  return {
    [ACC.checking]: { balanceMinor: bal, balanceMinorMain: bal },
    [ACC.savings]: { balanceMinor: bal, balanceMinorMain: bal },
  };
}

/** Two calendar months used in cross-month scenarios */
export function initialMonths(): Record<string, Record<string, unknown>> {
  return {
    "2026-03": emptyMonthBody("2026-03"),
    "2026-04": emptyMonthBody("2026-04"),
  };
}
