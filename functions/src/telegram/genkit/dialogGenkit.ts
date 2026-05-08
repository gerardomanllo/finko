import * as logger from "firebase-functions/logger";
import type { Genkit } from "genkit";

import type { AccountRow, CategoryRow } from "../ledgerToolkit";
import type { BotLocale } from "../sessions";
import type {
  ContinueDialogWithGeminiResult,
  FirstMessageAnalysis,
  GeminiTransactionSnapshot,
} from "../telegramGeminiSnapshot";
import { snapshotFromUnknown } from "../telegramGeminiSnapshot";
import { createTelegramLedgerReadTools } from "./ledgerTools";
import { TELEGRAM_GENKIT_MODEL_ID, telegramGenkit } from "./instance";
import { accountsSnippet, categoriesSnippet, replyLanguageInstructions, toolsHint } from "./promptContext";
import { continueDialogSchema, firstMessageAnalysisSchema, languageDetectSchema } from "./schemas";
import type { TelegramGenkitToolContext } from "./types";

function dialogIntentFromRaw(intentRaw: unknown): "greeting" | "question" | "transaction" {
  return intentRaw === "greeting" || intentRaw === "question" || intentRaw === "transaction"
    ? intentRaw
    : "transaction";
}

/**
 * Genkit-backed first message analysis (intent + optional transaction draft).
 */
export async function runTelegramDialogFirstGenkit(
  ai: Genkit,
  apiKey: string,
  mainCurrency: string,
  userText: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  locale: BotLocale,
  toolContext?: TelegramGenkitToolContext | null
): Promise<FirstMessageAnalysis | null> {
  const key = apiKey.trim();
  if (!key) return null;
  const accs = accountsSnippet(accounts);
  const expenseCats = categoriesSnippet(categories, "out");
  const incomeCats = categoriesSnippet(categories, "in");
  const langBlock = replyLanguageInstructions(locale);
  const tools =
    toolContext && toolContext.uid.length > 0
      ? createTelegramLedgerReadTools(ai, toolContext.db, toolContext.uid)
      : undefined;
  const toolBlock = tools ? `\n${toolsHint()}\n` : "";

  const prompt = `You are Finko's Telegram finance bot.

${langBlock}

Reply with structured output matching the schema (JSON fields).
{
  "intent": "greeting" | "question" | "transaction",
  "quickReply": string,
  "transaction": null | {
    "complete": boolean,
    "assistantMessage": string,
    "txKind": "standard" | "transfer" | null,
    "direction": "in" | "out" | null,
    "amountMinor": number | null,
    "amountMinorTo": number | null,
    "memo": string | null,
    "categoryId": string | null,
    "accountId": string | null,
    "transferFromId": string | null,
    "transferToId": string | null
  }
}

Rules:
- intent "greeting": hellos, thanks, bye — quickReply = short friendly reply (introduce as Finko assistant), in the mandatory reply language above.
- intent "question": about Finko features — quickReply = brief helpful answer (transactions via chat, /help, link app), in the mandatory reply language above.
- intent "transaction": user wants to log expense, income, or move money between accounts.
- For transaction: amounts as minor units (2 decimals in ${mainCurrency}), e.g. 12.50 -> 1250. Use null if unknown.
- txKind "standard": needs direction, amountMinor, memo, categoryId, accountId from lists below when possible.
- txKind "transfer": needs transferFromId, transferToId, amountMinor; if accounts use different currencies, also amountMinorTo for the destination leg.
- Never invent ids — only use ids from the lists or from tools. If unsure, leave fields null and complete false.
- assistantMessage: must never be empty when intent is transaction — always summarize what you understood and list missing fields, in the mandatory reply language above.
- quickReply: if intent is not transaction, the message to send; if transaction, repeat assistantMessage or use "". Same reply language as above.
${toolBlock}
ACCOUNTS (id:name (currency)): ${accs}
Expense categories: ${expenseCats}
Income categories: ${incomeCats}

User message:
${JSON.stringify(userText)}`;

  try {
    const res = await ai.generate({
      model: TELEGRAM_GENKIT_MODEL_ID,
      prompt,
      config: { apiKey: key },
      output: { schema: firstMessageAnalysisSchema },
      ...(tools ? { tools } : {}),
    });
    const out = res.output;
    if (!out) {
      logger.warn("telegramGenkit: analyzeFirst empty output", { model: TELEGRAM_GENKIT_MODEL_ID });
      return null;
    }
    const intent = dialogIntentFromRaw(out.intent);
    const quickReply = out.quickReply.trim().slice(0, 3500);
    let transaction: GeminiTransactionSnapshot | null = null;
    if (out.transaction) {
      transaction = snapshotFromUnknown(out.transaction as Record<string, unknown>);
    }
    return { intent, quickReply, transaction };
  } catch (e) {
    logger.warn("telegramGenkit: analyzeFirstMessage failed", {
      err: e instanceof Error ? e.message : String(e),
      model: TELEGRAM_GENKIT_MODEL_ID,
    });
    return null;
  }
}

/**
 * Genkit-backed continuation turn (merge draft + new user text).
 */
export async function runTelegramDialogContinueGenkit(
  ai: Genkit,
  apiKey: string,
  mainCurrency: string,
  userText: string,
  previous: GeminiTransactionSnapshot,
  categories: CategoryRow[],
  accounts: AccountRow[],
  locale: BotLocale,
  toolContext?: TelegramGenkitToolContext | null
): Promise<ContinueDialogWithGeminiResult | null> {
  const key = apiKey.trim();
  if (!key) return null;
  const accs = accountsSnippet(accounts);
  const expenseCats = categoriesSnippet(categories, "out");
  const incomeCats = categoriesSnippet(categories, "in");
  const langBlock = replyLanguageInstructions(locale);
  const prevJson = JSON.stringify(previous);
  const tools =
    toolContext && toolContext.uid.length > 0
      ? createTelegramLedgerReadTools(ai, toolContext.db, toolContext.uid)
      : undefined;
  const toolBlock = tools ? `\n${toolsHint()}\n` : "";

  const prompt = `You are Finko's Telegram finance bot.

${langBlock}

Update the transaction draft from the new user message. Structured output must match the schema:
{
  "dialogIntent": "transaction" | "greeting" | "question",
  "assistantMessage": string,
  "complete": boolean,
  "txKind": "standard" | "transfer" | null,
  "direction": "in" | "out" | null,
  "amountMinor": number | null,
  "amountMinorTo": number | null,
  "memo": string | null,
  "categoryId": string | null,
  "accountId": string | null,
  "transferFromId": string | null,
  "transferToId": string | null
}

Rules:
- dialogIntent "transaction": user is answering or refining a ledger entry. "greeting": only hi/thanks/small talk and not adding transaction data (abandon draft). "question": general how-to about Finko, not finishing the draft.
- assistantMessage: always non-empty, in the mandatory reply language above; for transaction explain what you have and what is still needed; for greeting/question give a short appropriate reply.
- Minor amounts in ${mainCurrency} minor units (e.g. 12.50 -> 1250). Valid ids only from lists or tools; never invent ids.
${toolBlock}
ACCOUNTS: ${accs}
Expense categories: ${expenseCats}
Income categories: ${incomeCats}

Previous extraction:
${prevJson}

New user message:
${JSON.stringify(userText)}`;

  try {
    const res = await ai.generate({
      model: TELEGRAM_GENKIT_MODEL_ID,
      prompt,
      config: { apiKey: key },
      output: { schema: continueDialogSchema },
      ...(tools ? { tools } : {}),
    });
    const out = res.output;
    if (!out) {
      logger.warn("telegramGenkit: continueDialog empty output", { model: TELEGRAM_GENKIT_MODEL_ID });
      return null;
    }
    const intentRaw = out.dialogIntent;
    const dialogIntent =
      intentRaw === "greeting" || intentRaw === "question" ? intentRaw : "transaction";
    const snap = snapshotFromUnknown(out as unknown as Record<string, unknown>);
    return { dialogIntent, snap };
  } catch (e) {
    logger.warn("telegramGenkit: continueDialog failed", {
      err: e instanceof Error ? e.message : String(e),
      model: TELEGRAM_GENKIT_MODEL_ID,
    });
    return null;
  }
}

export async function analyzeFirstMessageWithGenkit(
  apiKey: string,
  mainCurrency: string,
  userText: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  locale: BotLocale,
  toolContext?: TelegramGenkitToolContext | null
): Promise<FirstMessageAnalysis | null> {
  return runTelegramDialogFirstGenkit(
    telegramGenkit,
    apiKey,
    mainCurrency,
    userText,
    categories,
    accounts,
    locale,
    toolContext
  );
}

export async function continueDialogWithGenkit(
  apiKey: string,
  mainCurrency: string,
  userText: string,
  previous: GeminiTransactionSnapshot,
  categories: CategoryRow[],
  accounts: AccountRow[],
  locale: BotLocale,
  toolContext?: TelegramGenkitToolContext | null
): Promise<ContinueDialogWithGeminiResult | null> {
  return runTelegramDialogContinueGenkit(
    telegramGenkit,
    apiKey,
    mainCurrency,
    userText,
    previous,
    categories,
    accounts,
    locale,
    toolContext
  );
}

/** Strict ES/EN detection for each text message turn. */
export async function detectMessageLanguageWithGenkit(
  apiKey: string,
  userText: string
): Promise<"es" | "en" | null> {
  const key = apiKey.trim();
  if (!key) return null;
  const prompt = `Detect only the language of this user message.

Return structured output with field:
{
  "language": "es" | "en" | "unknown"
}

Rules:
- "es" for Spanish.
- "en" for English.
- "unknown" for any other language, mixed/ambiguous content, or if uncertain.
- Never infer from context outside this message.

User message:
${JSON.stringify(userText)}`;

  try {
    const res = await telegramGenkit.generate({
      model: TELEGRAM_GENKIT_MODEL_ID,
      prompt,
      config: { apiKey: key },
      output: { schema: languageDetectSchema },
    });
    const out = res.output;
    if (!out) return null;
    return out.language === "es" || out.language === "en" ? out.language : null;
  } catch (e) {
    logger.warn("telegramGenkit: detectMessageLanguage failed", {
      err: e instanceof Error ? e.message : String(e),
      model: TELEGRAM_GENKIT_MODEL_ID,
    });
    return null;
  }
}
