import type { AccountRow, CategoryRow } from "../ledgerToolkit";
import type { BotLocale } from "../sessions";

/** Strong instruction so model replies match Finko’s chosen Telegram bot UI language (not the user’s message language). */
export function replyLanguageInstructions(locale: BotLocale): string {
  if (locale === "en") {
    return `## Reply language (mandatory)
The user's Telegram bot UI locale is **English** (\`en\`). You MUST write **every user-visible string in English only** — including quickReply, assistantMessage, explanations, and any text meant for the user. Do **not** use Spanish or mix languages. Follow this locale even if the user's message is entirely in Spanish or another language.`;
  }
  return `## Reply language (mandatory)
The user's Telegram bot UI locale is **Spanish** (\`es\`). You MUST write **every user-visible string in Spanish only** — including quickReply, assistantMessage, explanations, and any text meant for the user. Do **not** use English or mix languages. Follow this locale even if the user's message is entirely in English or another language.`;
}

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
