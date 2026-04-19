import { computeLedgerUpdateOps } from "../src/ledgerAggregateMath";
import type { TxPayload } from "../src/ledgerAggregateMath";
import { isLedgerDateEffectiveForAggregate } from "../src/userToday";
import {
  ACC,
  CAT,
  CURRENCY_MXN,
  initialAccounts,
  initialMonths,
  USER_TODAY_YMD,
} from "./fixtures/ledgerWorld";
import { simulateAggregateOps } from "./helpers/simulateAggregateOps";

describe("ledger scenarios (mock world)", () => {
  const stdExpense = (d: string, amount: number, accountId: string): TxPayload => ({
    transactionDate: d,
    amountMinor: amount,
    direction: "out",
    currency: CURRENCY_MXN,
    type: "standard",
    accountId,
    categoryId: CAT.food,
  });

  const transferOut = (d: string, amount: number): TxPayload => ({
    transactionDate: d,
    amountMinor: amount,
    direction: "out",
    currency: CURRENCY_MXN,
    type: "transferLeg",
    accountId: ACC.checking,
  });

  const transferIn = (d: string, amount: number, accountId: string = ACC.savings): TxPayload => ({
    transactionDate: d,
    amountMinor: amount,
    direction: "in",
    currency: CURRENCY_MXN,
    type: "transferLeg",
    accountId,
  });

  it("past expense updates account, month totals, category, and day", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const amountMain = 12_345;
    const tx = stdExpense("2026-04-10", amountMain, ACC.checking);

    expect(isLedgerDateEffectiveForAggregate(tx.transactionDate, USER_TODAY_YMD)).toBe(true);

    simulateAggregateOps([{ tx, sign: 1, amountMain }], accounts, months);

    expect(accounts[ACC.checking].balanceMinor).toBe(1_000_000 - amountMain);
    expect(months["2026-04"].expenseMinorMain).toBe(amountMain);
    expect((months["2026-04"].byCategoryMinorMain as Record<string, number>)[CAT.food]).toBe(
      -amountMain
    );
    const days = months["2026-04"].days as Record<string, Record<string, unknown>>;
    expect(days["10"].expenseMinorMain).toBe(amountMain);
  });

  it("full reversal restores month and account", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const amountMain = 12_345;
    const tx = stdExpense("2026-04-10", amountMain, ACC.checking);

    simulateAggregateOps([{ tx, sign: 1, amountMain }], accounts, months);
    simulateAggregateOps([{ tx, sign: -1, amountMain }], accounts, months);

    expect(accounts[ACC.checking]).toEqual(initialAccounts()[ACC.checking]);
    expect(months["2026-04"].expenseMinorMain).toBe(0);
    expect((months["2026-04"].byCategoryMinorMain as Record<string, number>)[CAT.food] ?? 0).toBe(
      0
    );
  });

  it("transfer legs move both accounts and skip monthly cashflow", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const amt = 50_000;
    const d = "2026-04-12";
    const ops = [
      { tx: transferOut(d, amt), sign: 1 as const, amountMain: amt },
      { tx: transferIn(d, amt, ACC.savings), sign: 1 as const, amountMain: amt },
    ];

    simulateAggregateOps(ops, accounts, months);

    expect(accounts[ACC.checking].balanceMinor).toBe(1_000_000 - amt);
    expect(accounts[ACC.savings].balanceMinor).toBe(1_000_000 + amt);
    expect(months["2026-04"].expenseMinorMain).toBe(0);
    expect(months["2026-04"].incomeMinorMain).toBe(0);
    expect(Object.keys((months["2026-04"].byCategoryMinorMain as object) ?? {})).toHaveLength(0);
  });

  it("cross-month update moves buckets between March and April", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const amountMain = 8_000;
    const before = stdExpense("2026-03-20", amountMain, ACC.checking);
    const after = stdExpense("2026-04-05", amountMain, ACC.checking);

    // Row was already applied in March; update replaces it with April posting.
    simulateAggregateOps([{ tx: before, sign: 1, amountMain }], accounts, months);
    const ops = computeLedgerUpdateOps(true, true, true, before, after, amountMain, amountMain);
    simulateAggregateOps(ops, accounts, months);

    expect(months["2026-03"].expenseMinorMain).toBe(0);
    expect(months["2026-04"].expenseMinorMain).toBe(amountMain);
    const d03 = months["2026-03"].days as Record<string, Record<string, unknown>>;
    const d04 = months["2026-04"].days as Record<string, Record<string, unknown>>;
    expect(d03["20"]?.expenseMinorMain ?? 0).toBe(0);
    expect(d04["05"]?.expenseMinorMain).toBe(amountMain);
  });

  it("future posting date is not effective vs fixture today (excluded from aggregates gate)", () => {
    expect(isLedgerDateEffectiveForAggregate("2026-05-01", USER_TODAY_YMD)).toBe(false);
  });

  it("update from past to future only reverses before state", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const amountMain = 3_000;
    const before = stdExpense("2026-04-10", amountMain, ACC.checking);
    const after = { ...before, transactionDate: "2026-05-20" };

    simulateAggregateOps([{ tx: before, sign: 1, amountMain }], accounts, months);
    expect(months["2026-04"].expenseMinorMain).toBe(amountMain);

    const updateOps = computeLedgerUpdateOps(
      true,
      false,
      true,
      before,
      after,
      amountMain,
      amountMain
    );
    simulateAggregateOps(updateOps, accounts, months);

    expect(months["2026-04"].expenseMinorMain).toBe(0);
    expect(accounts[ACC.checking].balanceMinor).toBe(1_000_000);
  });

  it("salary inflow updates income and category net", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const amountMain = 50_000;
    const tx: TxPayload = {
      transactionDate: "2026-04-01",
      amountMinor: amountMain,
      direction: "in",
      currency: CURRENCY_MXN,
      type: "standard",
      accountId: ACC.checking,
      categoryId: CAT.salary,
    };

    simulateAggregateOps([{ tx, sign: 1, amountMain }], accounts, months);

    expect(months["2026-04"].incomeMinorMain).toBe(amountMain);
    expect((months["2026-04"].byCategoryMinorMain as Record<string, number>)[CAT.salary]).toBe(
      amountMain
    );
    expect(accounts[ACC.checking].balanceMinor).toBe(1_000_000 + amountMain);
  });

  it("credit card expense increases balance owed (liability)", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const amountMain = 15_000;
    const tx = stdExpense("2026-04-11", amountMain, ACC.creditCard);

    simulateAggregateOps([{ tx, sign: 1, amountMain }], accounts, months);

    expect(accounts[ACC.creditCard].balanceMinor).toBe(amountMain);
    expect(months["2026-04"].expenseMinorMain).toBe(amountMain);
  });

  it("transfer payment to credit card reduces balance owed", () => {
    const accounts = initialAccounts();
    const months = initialMonths();
    const amt = 40_000;
    const d = "2026-04-14";
    const charge = stdExpense(d, amt, ACC.creditCard);
    simulateAggregateOps([{ tx: charge, sign: 1, amountMain: amt }], accounts, months);
    expect(accounts[ACC.creditCard].balanceMinor).toBe(amt);

    const ops = [
      { tx: transferOut(d, amt), sign: 1 as const, amountMain: amt },
      { tx: transferIn(d, amt, ACC.creditCard), sign: 1 as const, amountMain: amt },
    ];
    simulateAggregateOps(ops, accounts, months);

    expect(accounts[ACC.checking].balanceMinor).toBe(1_000_000 - amt);
    expect(accounts[ACC.creditCard].balanceMinor).toBe(0);
    expect(months["2026-04"].expenseMinorMain).toBe(amt);
  });
});
