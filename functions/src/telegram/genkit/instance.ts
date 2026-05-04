import { genkit } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

/** Runtime API key comes from `config.apiKey` on each `generate` (Telegram secret), not from env. */
const googlePlugin = googleAI({ apiKey: false });

export const telegramGenkit = genkit({
  name: "finko-telegram",
  plugins: [googlePlugin],
});

/** Aligned with Genkit docs (`googleai/…` prefix required). */
export const TELEGRAM_GENKIT_MODEL_ID = "googleai/gemini-2.5-flash" as const;
