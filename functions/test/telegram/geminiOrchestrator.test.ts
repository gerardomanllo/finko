import {
  classifyDialogIntentHeuristic,
  EMPTY_TRANSACTION_SNAPSHOT,
  validateTransactionSnapshot,
} from "../../src/telegram/geminiOrchestrator";

describe("geminiOrchestrator", () => {
  const accounts = [
    { id: "a1", name: "Cash", currency: "MXN" },
    { id: "a2", name: "Savings", currency: "MXN" },
    { id: "a3", name: "USD", currency: "USD" },
  ];
  const categories = [
    { id: "c1", name: "Food", kind: "expense" },
    { id: "c2", name: "Salary", kind: "income" },
  ];

  it("validateTransactionSnapshot accepts standard expense", () => {
    const snap = {
      ...EMPTY_TRANSACTION_SNAPSHOT,
      txKind: "standard" as const,
      direction: "out" as const,
      amountMinor: 1000,
      memo: "lunch",
      categoryId: "c1",
      accountId: "a1",
    };
    expect(validateTransactionSnapshot(snap, categories, accounts).ok).toBe(true);
  });

  it("validateTransactionSnapshot accepts transfer same currency", () => {
    const snap = {
      ...EMPTY_TRANSACTION_SNAPSHOT,
      txKind: "transfer" as const,
      transferFromId: "a1",
      transferToId: "a2",
      amountMinor: 500,
    };
    expect(validateTransactionSnapshot(snap, categories, accounts).ok).toBe(true);
  });

  it("validateTransactionSnapshot requires amountMinorTo for cross-currency transfer", () => {
    const snap = {
      ...EMPTY_TRANSACTION_SNAPSHOT,
      txKind: "transfer" as const,
      transferFromId: "a1",
      transferToId: "a3",
      amountMinor: 10000,
      amountMinorTo: null,
    };
    expect(validateTransactionSnapshot(snap, categories, accounts).ok).toBe(false);
  });

  it("classifyDialogIntentHeuristic treats amount+note as transaction", () => {
    expect(classifyDialogIntentHeuristic("50 coffee".toLowerCase(), "50 coffee", "MXN")).toBe(
      "transaction"
    );
  });
});
