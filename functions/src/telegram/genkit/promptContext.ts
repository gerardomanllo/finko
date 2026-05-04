import type { AccountRow, CategoryRow } from "../ledgerToolkit";

export function categoriesSnippet(categories: CategoryRow[], direction: "in" | "out"): string {
  const kind = direction === "in" ? "income" : "expense";
  return categories
    .filter((c) => c.kind === kind)
    .slice(0, 40)
    .map((c) => `${c.id}:${c.name}`)
    .join("; ");
}

export function accountsSnippet(accounts: AccountRow[]): string {
  return accounts.slice(0, 40).map((a) => `${a.id}:${a.name} (${a.currency})`).join("; ");
}

export function toolsHint(): string {
  return `Optional tools (prefer when lists above might be stale or incomplete):
- list_accounts: refresh account ids/names/currencies.
- list_categories: refresh category ids/names/kinds (income vs expense).
- recent_transactions: last few posted transactions (memo, amount, direction).`;
}
