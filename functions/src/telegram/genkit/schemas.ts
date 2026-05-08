import { z } from "genkit";

/** Shared transaction snapshot shape from the model (server still runs validateTransactionSnapshot). */
export const geminiTransactionSnapshotSchema = z.object({
  complete: z.boolean().describe("Whether the model believes all required fields are present."),
  assistantMessage: z
    .string()
    .describe("User-facing reply in the requested language; never empty for transaction turns."),
  txKind: z.enum(["standard", "transfer"]).nullable().describe("Ledger entry kind or null if unclear."),
  direction: z.enum(["in", "out"]).nullable(),
  amountMinor: z.number().int().positive().nullable(),
  amountMinorTo: z.number().int().positive().nullable(),
  memo: z.string().nullable(),
  categoryId: z.string().nullable(),
  accountId: z.string().nullable(),
  transferFromId: z.string().nullable(),
  transferToId: z.string().nullable(),
});

export const firstMessageAnalysisSchema = z.object({
  intent: z.enum(["greeting", "question", "transaction"]),
  quickReply: z.string().describe("Message to send when intent is not transaction; may mirror assistantMessage for transaction."),
  transaction: geminiTransactionSnapshotSchema.nullable(),
});

export const continueDialogSchema = z.object({
  dialogIntent: z.enum(["transaction", "greeting", "question"]),
  assistantMessage: z.string(),
  complete: z.boolean(),
  txKind: z.enum(["standard", "transfer"]).nullable(),
  direction: z.enum(["in", "out"]).nullable(),
  amountMinor: z.number().int().positive().nullable(),
  amountMinorTo: z.number().int().positive().nullable(),
  memo: z.string().nullable(),
  categoryId: z.string().nullable(),
  accountId: z.string().nullable(),
  transferFromId: z.string().nullable(),
  transferToId: z.string().nullable(),
});

export const languageDetectSchema = z.object({
  language: z.enum(["es", "en", "unknown"]),
});

export const nluLineSchema = z.object({
  amountMinor: z.number().int().positive().nullable(),
  memo: z.string().nullable(),
  direction: z.enum(["in", "out"]),
  categoryId: z.string().nullable(),
  accountId: z.string().nullable(),
});
