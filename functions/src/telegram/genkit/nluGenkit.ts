import * as logger from "firebase-functions/logger";
import type { Genkit } from "genkit";

import type { AccountRow, CategoryRow } from "../ledgerToolkit";
import { parseSpendLine } from "../parseTxText";
import { createTelegramLedgerReadTools } from "./ledgerTools";
import { TELEGRAM_GENKIT_MODEL_ID, telegramGenkit } from "./instance";
import { accountsSnippet, categoriesSnippet, toolsHint } from "./promptContext";
import { nluLineSchema } from "./schemas";
import type { TelegramGenkitToolContext } from "./types";

export type NluParseResult = {
  amountMinor: number | null;
  memo: string;
  direction: "in" | "out";
  categoryId?: string;
  accountId?: string;
};

function heuristicToNlu(h: ReturnType<typeof parseSpendLine>): NluParseResult | null {
  if (!h) return null;
  return { amountMinor: h.amountMinor, memo: h.memo, direction: h.direction };
}

function nluJsonInstruction(mainCurrency: string): string {
  return `Reply with structured output for:
{"amountMinor":number|null,"memo":string|null,"direction":"in"|"out","categoryId":string|null,"accountId":string|null}
Rules:
- User may write in Spanish or English (e.g. "gasté 100 pesos en el super", "spent 12.50 on coffee").
- amountMinor: minor units (2 decimals) in the user's MAIN currency (${mainCurrency}). Examples: 12.50 -> 1250. Use null if amount unknown.
- memo: short merchant/description, or null if unknown.
- direction: "out" for spending, "in" for income.
- categoryId: exactly one id from the matching list for direction, or null.
- accountId: exactly one id from the ACCOUNTS list, or null if unknown.
Never use 0 for a missing amount; use null instead.`;
}

function validateParsedIds(
  categories: CategoryRow[],
  accounts: AccountRow[],
  direction: "in" | "out",
  categoryId: string | undefined,
  accountId: string | undefined
): { categoryId?: string; accountId?: string } {
  const kind = direction === "in" ? "income" : "expense";
  const catOk =
    categoryId && categories.some((c) => c.id === categoryId && c.kind === kind) ? categoryId : undefined;
  const accOk = accountId && accounts.some((a) => a.id === accountId) ? accountId : undefined;
  return { categoryId: catOk, accountId: accOk };
}

function dataUri(mimeType: string, base64: string): string {
  const mt = mimeType.trim().length > 0 ? mimeType : "application/octet-stream";
  return `data:${mt};base64,${base64}`;
}

async function generateNluLine(
  ai: Genkit,
  apiKey: string,
  mainCurrency: string,
  text: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  const key = apiKey.trim();
  if (!key) return null;
  const expenseCats = categoriesSnippet(categories, "out");
  const incomeCats = categoriesSnippet(categories, "in");
  const accs = accountsSnippet(accounts);
  const tools =
    toolContext && toolContext.uid.length > 0
      ? createTelegramLedgerReadTools(ai, toolContext.db, toolContext.uid)
      : undefined;
  const toolBlock = tools ? `\n${toolsHint()}\n` : "";
  const prompt = `${nluJsonInstruction(mainCurrency)}
${toolBlock}
ACCOUNTS (id:name (currency)): ${accs}
Expense categories (id:name): ${expenseCats}
Income categories (id:name): ${incomeCats}

User message:
${JSON.stringify(text)}`;

  const res = await ai.generate({
    model: TELEGRAM_GENKIT_MODEL_ID,
    prompt,
    config: { apiKey: key },
    output: { schema: nluLineSchema },
    ...(tools ? { tools } : {}),
  });
  const parsed = res.output;
  if (!parsed) return null;
  const amountMinor =
    parsed.amountMinor != null && Number.isFinite(parsed.amountMinor) && parsed.amountMinor > 0
      ? Math.round(parsed.amountMinor)
      : null;
  const memoRaw = parsed.memo;
  const memo =
    typeof memoRaw === "string" ? memoRaw.trim().slice(0, 200) : memoRaw === null ? "" : "";
  const direction = parsed.direction === "in" || parsed.direction === "out" ? parsed.direction : "out";
  const rawCat =
    typeof parsed.categoryId === "string" && parsed.categoryId.trim().length > 0
      ? parsed.categoryId.trim()
      : undefined;
  const rawAcc =
    typeof parsed.accountId === "string" && parsed.accountId.trim().length > 0
      ? parsed.accountId.trim()
      : undefined;
  const { categoryId, accountId } = validateParsedIds(categories, accounts, direction, rawCat, rawAcc);
  return { amountMinor, memo, direction, categoryId, accountId };
}

/**
 * Text line NLU: Genkit when key present; heuristics otherwise ([parseSpendLine]).
 */
export async function parseTransactionLineWithGenkit(
  ai: Genkit,
  apiKey: string | undefined,
  mainCurrency: string,
  text: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  const cleaned = text.replace(/^\/\/\s*/, "");
  const heuristic = parseSpendLine(mainCurrency, cleaned);
  if (!apiKey || apiKey.trim().length === 0) {
    return heuristicToNlu(heuristic);
  }
  if (heuristic) {
    return heuristicToNlu(heuristic);
  }
  try {
    return await generateNluLine(ai, apiKey, mainCurrency, text, categories, accounts, toolContext);
  } catch (e) {
    logger.warn("telegramGenkit: parseTransactionLine failed", {
      err: e instanceof Error ? e.message : String(e),
      model: TELEGRAM_GENKIT_MODEL_ID,
    });
    return heuristicToNlu(heuristic);
  }
}

export async function parseReceiptCaptionWithGenkit(
  ai: Genkit,
  apiKey: string | undefined,
  mainCurrency: string,
  caption: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  return parseTransactionLineWithGenkit(ai, apiKey, mainCurrency, caption, categories, accounts, toolContext);
}

export async function parseReceiptImageWithGenkit(
  ai: Genkit,
  apiKey: string | undefined,
  mainCurrency: string,
  imageBytes: Buffer,
  mimeType: string,
  caption: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  const cap =
    caption.trim().length > 0
      ? await parseTransactionLineWithGenkit(
          ai,
          apiKey,
          mainCurrency,
          caption,
          categories,
          accounts,
          toolContext
        )
      : null;
  if (cap && cap.amountMinor != null && cap.amountMinor > 0) return cap;
  if (!apiKey?.trim()) return cap ?? null;

  const expenseCats = categoriesSnippet(categories, "out");
  const incomeCats = categoriesSnippet(categories, "in");
  const accs = accountsSnippet(accounts);
  const b64 = imageBytes.toString("base64");
  const tools =
    toolContext && toolContext.uid.length > 0
      ? createTelegramLedgerReadTools(ai, toolContext.db, toolContext.uid)
      : undefined;
  const toolBlock = tools ? `\n${toolsHint()}\n` : "";
  const prompt = `Read this receipt image. Structured output:
{"amountMinor":number|null,"memo":string|null,"direction":"in"|"out","categoryId":string|null,"accountId":string|null}
amountMinor = total paid in minor units (2 decimals) in ${mainCurrency}, or null if unreadable.
direction is usually "out" for purchases.
categoryId: expense id from list or null: ${expenseCats}
accountId: one of ${accs} or null
Income categories (rare): ${incomeCats}
${toolBlock}`;

  try {
    const res = await ai.generate({
      model: TELEGRAM_GENKIT_MODEL_ID,
      prompt: [{ media: { url: dataUri(mimeType || "image/jpeg", b64) } }, { text: prompt }],
      config: { apiKey: apiKey.trim() },
      output: { schema: nluLineSchema },
      ...(tools ? { tools } : {}),
    });
    const parsed = res.output;
    if (!parsed) return cap ?? null;
    const amountMinor =
      parsed.amountMinor != null && Number.isFinite(parsed.amountMinor) && parsed.amountMinor > 0
        ? Math.round(parsed.amountMinor)
        : null;
    const memoRaw = parsed.memo;
    const memo =
      typeof memoRaw === "string"
        ? memoRaw.trim().slice(0, 200)
        : memoRaw === null
          ? ""
          : "Receipt";
    const direction = parsed.direction === "in" || parsed.direction === "out" ? parsed.direction : "out";
    const rawCat =
      typeof parsed.categoryId === "string" && parsed.categoryId.trim().length > 0
        ? parsed.categoryId.trim()
        : undefined;
    const rawAcc =
      typeof parsed.accountId === "string" && parsed.accountId.trim().length > 0
        ? parsed.accountId.trim()
        : undefined;
    const { categoryId, accountId } = validateParsedIds(categories, accounts, direction, rawCat, rawAcc);
    if (amountMinor == null || amountMinor <= 0) return cap ?? null;
    return {
      amountMinor,
      memo: memo.length > 0 ? memo : "Receipt",
      direction,
      categoryId,
      accountId,
    };
  } catch (e) {
    logger.warn("telegramGenkit: parseReceiptImage failed", {
      err: e instanceof Error ? e.message : String(e),
      model: TELEGRAM_GENKIT_MODEL_ID,
    });
    return cap ?? null;
  }
}

export async function parseVoiceBytesWithGenkit(
  ai: Genkit,
  apiKey: string | undefined,
  mainCurrency: string,
  audioBytes: Buffer,
  mimeType: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  if (!apiKey?.trim()) return null;
  const expenseCats = categoriesSnippet(categories, "out");
  const incomeCats = categoriesSnippet(categories, "in");
  const accs = accountsSnippet(accounts);
  const b64 = audioBytes.toString("base64");
  const tools =
    toolContext && toolContext.uid.length > 0
      ? createTelegramLedgerReadTools(ai, toolContext.db, toolContext.uid)
      : undefined;
  const toolBlock = tools ? `\n${toolsHint()}\n` : "";
  const prompt = `Transcribe this short voice note about money. Structured output:
{"amountMinor":number|null,"memo":string|null,"direction":"in"|"out","categoryId":string|null,"accountId":string|null}
Use minor units (2 decimals) in ${mainCurrency} or null if amount unknown.
categoryId from lists or null.
accountId: one of ${accs} or null
Expense: ${expenseCats}
Income: ${incomeCats}
${toolBlock}`;

  try {
    const res = await ai.generate({
      model: TELEGRAM_GENKIT_MODEL_ID,
      prompt: [{ media: { url: dataUri(mimeType || "audio/ogg", b64) } }, { text: prompt }],
      config: { apiKey: apiKey.trim() },
      output: { schema: nluLineSchema },
      ...(tools ? { tools } : {}),
    });
    const parsed = res.output;
    if (!parsed) return null;
    const amountMinor =
      parsed.amountMinor != null && Number.isFinite(parsed.amountMinor) && parsed.amountMinor > 0
        ? Math.round(parsed.amountMinor)
        : null;
    const memoRaw = parsed.memo;
    const memo =
      typeof memoRaw === "string" ? memoRaw.trim().slice(0, 200) : memoRaw === null ? "" : "Voice";
    const direction = parsed.direction === "in" || parsed.direction === "out" ? parsed.direction : "out";
    const rawCat =
      typeof parsed.categoryId === "string" && parsed.categoryId.trim().length > 0
        ? parsed.categoryId.trim()
        : undefined;
    const rawAcc =
      typeof parsed.accountId === "string" && parsed.accountId.trim().length > 0
        ? parsed.accountId.trim()
        : undefined;
    const { categoryId, accountId } = validateParsedIds(categories, accounts, direction, rawCat, rawAcc);
    if (amountMinor == null || amountMinor <= 0) return null;
    return {
      amountMinor,
      memo: memo.length > 0 ? memo : "Voice",
      direction,
      categoryId,
      accountId,
    };
  } catch (e) {
    logger.warn("telegramGenkit: parseVoice failed", {
      err: e instanceof Error ? e.message : String(e),
      model: TELEGRAM_GENKIT_MODEL_ID,
    });
    return null;
  }
}

export async function parseTransactionLineWithOptionalGenkit(
  apiKey: string | undefined,
  mainCurrency: string,
  text: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  return parseTransactionLineWithGenkit(
    telegramGenkit,
    apiKey,
    mainCurrency,
    text,
    categories,
    accounts,
    toolContext
  );
}

export async function parseReceiptCaptionWithOptionalGenkit(
  apiKey: string | undefined,
  mainCurrency: string,
  caption: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  return parseReceiptCaptionWithGenkit(
    telegramGenkit,
    apiKey,
    mainCurrency,
    caption,
    categories,
    accounts,
    toolContext
  );
}

export async function parseReceiptImageWithOptionalGenkit(
  apiKey: string | undefined,
  mainCurrency: string,
  imageBytes: Buffer,
  mimeType: string,
  caption: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  return parseReceiptImageWithGenkit(
    telegramGenkit,
    apiKey,
    mainCurrency,
    imageBytes,
    mimeType,
    caption,
    categories,
    accounts,
    toolContext
  );
}

export async function parseVoiceBytesWithOptionalGenkit(
  apiKey: string | undefined,
  mainCurrency: string,
  audioBytes: Buffer,
  mimeType: string,
  categories: CategoryRow[],
  accounts: AccountRow[],
  toolContext?: TelegramGenkitToolContext | null
): Promise<NluParseResult | null> {
  return parseVoiceBytesWithGenkit(
    telegramGenkit,
    apiKey,
    mainCurrency,
    audioBytes,
    mimeType,
    categories,
    accounts,
    toolContext
  );
}
