import { GoogleGenerativeAI } from "@google/generative-ai";

import type { CategoryRow } from "./ledgerToolkit";
import { parseSpendLine } from "./parseTxText";

export type NluParseResult = {
  amountMinor: number;
  memo: string;
  direction: "in" | "out";
  categoryId?: string;
};

function stripJsonFence(raw: string): string {
  let s = raw.trim();
  if (s.startsWith("```")) {
    s = s.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/u, "").trim();
  }
  return s;
}

function categoriesSnippet(categories: CategoryRow[], direction: "in" | "out"): string {
  const kind = direction === "in" ? "income" : "expense";
  const filtered = categories.filter((c) => c.kind === kind).slice(0, 40);
  return filtered.map((c) => `${c.id}:${c.name}`).join("; ");
}

/**
 * Uses Gemini when `apiKey` is non-empty; otherwise heuristic-only ([parseSpendLine]).
 */
export async function parseTransactionLineWithOptionalGemini(
  apiKey: string | undefined,
  mainCurrency: string,
  text: string,
  categories: CategoryRow[]
): Promise<NluParseResult | null> {
  const heuristic = parseSpendLine(mainCurrency, text.replace(/^\/\/\s*/, ""));
  if (!apiKey || apiKey.trim().length === 0) {
    return heuristic;
  }

  try {
    const genai = new GoogleGenerativeAI(apiKey.trim());
    const model = genai.getGenerativeModel({
      model: "gemini-1.5-flash",
    });

    const expenseCats = categoriesSnippet(categories, "out");
    const incomeCats = categoriesSnippet(categories, "in");

    const prompt = `You classify a personal finance chat message into JSON only (no markdown).
Fields:
- amountMinor: integer minor currency units (2 decimals). Example 12.50 -> 1250.
- memo: short memo from user's note if present else "Expense" or "Income".
- direction: "out" for spending, "in" for income.
- categoryId: exactly one id from lists below or null.

Expense categories (id:name): ${expenseCats}
Income categories (id:name): ${incomeCats}

User message:
${JSON.stringify(text)}

Reply ONLY compact JSON: {"amountMinor":number,"memo":string,"direction":"in"|"out","categoryId":string|null}`;

    const res = await model.generateContent(prompt);
    const raw = stripJsonFence(res.response.text());
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    const amountMinor =
      typeof parsed.amountMinor === "number"
        ? Math.round(parsed.amountMinor)
        : typeof parsed.amountMinor === "string"
          ? Math.round(Number(parsed.amountMinor))
          : NaN;
    const memo = typeof parsed.memo === "string" ? parsed.memo.trim().slice(0, 200) : "";
    const direction =
      parsed.direction === "in" || parsed.direction === "out" ? parsed.direction : "out";
    const categoryId =
      typeof parsed.categoryId === "string" && parsed.categoryId.trim().length > 0
        ? parsed.categoryId.trim()
        : undefined;

    if (!Number.isFinite(amountMinor) || amountMinor <= 0 || memo.length === 0) {
      return heuristic;
    }

    const allowedIds = new Set(categories.map((c) => c.id));
    const catOk = categoryId && allowedIds.has(categoryId) ? categoryId : undefined;
    const kindOk = categories.find((c) => c.id === catOk)?.kind === (direction === "in" ? "income" : "expense");

    return {
      amountMinor,
      memo,
      direction,
      categoryId: kindOk ? catOk : undefined,
    };
  } catch {
    return heuristic;
  }
}

export async function parseReceiptCaptionWithOptionalGemini(
  apiKey: string | undefined,
  mainCurrency: string,
  caption: string,
  categories: CategoryRow[]
): Promise<NluParseResult | null> {
  return parseTransactionLineWithOptionalGemini(apiKey, mainCurrency, caption, categories);
}

export async function parseReceiptImageWithOptionalGemini(
  apiKey: string | undefined,
  mainCurrency: string,
  imageBytes: Buffer,
  mimeType: string,
  caption: string,
  categories: CategoryRow[]
): Promise<NluParseResult | null> {
  const cap =
    caption.trim().length > 0
      ? await parseTransactionLineWithOptionalGemini(apiKey, mainCurrency, caption, categories)
      : null;
  if (cap && cap.amountMinor > 0) return cap;
  if (!apiKey?.trim()) return cap ?? null;

  try {
    const genai = new GoogleGenerativeAI(apiKey.trim());
    const model = genai.getGenerativeModel({ model: "gemini-1.5-flash" });
    const expenseCats = categoriesSnippet(categories, "out");
    const incomeCats = categoriesSnippet(categories, "in");
    const b64 = imageBytes.toString("base64");
    const prompt = `Read this receipt image. Reply ONLY compact JSON:
{"amountMinor":number,"memo":string,"direction":"in"|"out","categoryId":string|null}
amountMinor = total paid in minor units (2 decimals) in ${mainCurrency}.
direction is usually "out" for purchases.
categoryId must be one of these expense ids or null: ${expenseCats}
Income ids (rare): ${incomeCats}`;

    const res = await model.generateContent([
      { inlineData: { mimeType: mimeType || "image/jpeg", data: b64 } },
      { text: prompt },
    ]);
    const raw = stripJsonFence(res.response.text());
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    const amountMinor =
      typeof parsed.amountMinor === "number"
        ? Math.round(parsed.amountMinor)
        : typeof parsed.amountMinor === "string"
          ? Math.round(Number(parsed.amountMinor))
          : NaN;
    const memo = typeof parsed.memo === "string" ? parsed.memo.trim().slice(0, 200) : "Receipt";
    const direction =
      parsed.direction === "in" || parsed.direction === "out" ? parsed.direction : "out";
    const categoryId =
      typeof parsed.categoryId === "string" && parsed.categoryId.trim().length > 0
        ? parsed.categoryId.trim()
        : undefined;
    if (!Number.isFinite(amountMinor) || amountMinor <= 0) return cap ?? null;
    const allowedIds = new Set(categories.map((c) => c.id));
    const catOk = categoryId && allowedIds.has(categoryId) ? categoryId : undefined;
    const kindOk =
      categories.find((c) => c.id === catOk)?.kind === (direction === "in" ? "income" : "expense");
    return {
      amountMinor,
      memo: memo.length > 0 ? memo : "Receipt",
      direction,
      categoryId: kindOk ? catOk : undefined,
    };
  } catch {
    return cap ?? null;
  }
}

export async function parseVoiceBytesWithOptionalGemini(
  apiKey: string | undefined,
  mainCurrency: string,
  audioBytes: Buffer,
  mimeType: string,
  categories: CategoryRow[]
): Promise<NluParseResult | null> {
  if (!apiKey?.trim()) return null;
  try {
    const genai = new GoogleGenerativeAI(apiKey.trim());
    const model = genai.getGenerativeModel({ model: "gemini-1.5-flash" });
    const expenseCats = categoriesSnippet(categories, "out");
    const incomeCats = categoriesSnippet(categories, "in");
    const b64 = audioBytes.toString("base64");
    const prompt = `Transcribe this short voice note about money. Reply ONLY compact JSON:
{"amountMinor":number,"memo":string,"direction":"in"|"out","categoryId":string|null}
Use minor units (2 decimals) in ${mainCurrency}. categoryId from lists or null.
Expense: ${expenseCats}
Income: ${incomeCats}`;

    const res = await model.generateContent([
      { inlineData: { mimeType: mimeType || "audio/ogg", data: b64 } },
      { text: prompt },
    ]);
    const raw = stripJsonFence(res.response.text());
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    const amountMinor =
      typeof parsed.amountMinor === "number"
        ? Math.round(parsed.amountMinor)
        : typeof parsed.amountMinor === "string"
          ? Math.round(Number(parsed.amountMinor))
          : NaN;
    const memo = typeof parsed.memo === "string" ? parsed.memo.trim().slice(0, 200) : "Voice";
    const direction =
      parsed.direction === "in" || parsed.direction === "out" ? parsed.direction : "out";
    const categoryId =
      typeof parsed.categoryId === "string" && parsed.categoryId.trim().length > 0
        ? parsed.categoryId.trim()
        : undefined;
    if (!Number.isFinite(amountMinor) || amountMinor <= 0) return null;
    const allowedIds = new Set(categories.map((c) => c.id));
    const catOk = categoryId && allowedIds.has(categoryId) ? categoryId : undefined;
    const kindOk =
      categories.find((c) => c.id === catOk)?.kind === (direction === "in" ? "income" : "expense");
    return {
      amountMinor,
      memo: memo.length > 0 ? memo : "Voice",
      direction,
      categoryId: kindOk ? catOk : undefined,
    };
  } catch {
    return null;
  }
}
