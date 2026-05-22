import {
  parseReceiptCaptionWithOptionalGemini,
  parseReceiptImageWithOptionalGemini,
  parseVoiceBytesWithOptionalGemini,
} from "../../../telegram/geminiNlu";
import { beginSpendFlow, type TelegramHandleDeps } from "../../../telegram/handleUpdate";
import {
  loadAccountsForBot,
  loadAgentPreferences,
  loadCategoriesForBot,
  loadMainCurrency,
} from "../../../telegram/ledgerToolkit";
import { pickBotLocale } from "../../../telegram/localeInference";
import { AgentStatusKeys } from "../../core/statusKeys";
import type { AppAgentSink } from "./appSink";

export async function handleAppPhotoBytes(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  bytes: Buffer,
  mime: string,
  caption: string,
  deps: TelegramHandleDeps,
  sink: AppAgentSink
): Promise<void> {
  const prefs = await loadAgentPreferences(deps.db, uid);
  const locale = pickBotLocale({
    localeOverride: prefs.localeOverride,
    userText: caption || undefined,
  });
  await sink.onStatus(AgentStatusKeys.readingReceipt);
  const accounts = await loadAccountsForBot(deps.db, uid);
  const categories = await loadCategoriesForBot(deps.db, uid);
  const mainCurrency = await loadMainCurrency(deps.db, uid);
  const genkitToolContext = { db: deps.db, uid };
  let parsed = null as Awaited<ReturnType<typeof parseReceiptImageWithOptionalGemini>>;
  if (caption.trim().length > 0) {
    parsed = await parseReceiptCaptionWithOptionalGemini(
      deps.geminiApiKey,
      mainCurrency,
      caption,
      categories,
      accounts,
      locale,
      genkitToolContext
    );
  }
  if (bytes.length > 0) {
    await sink.onStatus(AgentStatusKeys.extractingAmount);
    parsed = await parseReceiptImageWithOptionalGemini(
      deps.geminiApiKey,
      mainCurrency,
      bytes,
      mime,
      caption,
      categories,
      accounts,
      locale,
      genkitToolContext
    );
  }
  if (!parsed) {
    await sink.markFailed("agentError.media");
    return;
  }
  await beginSpendFlow(uid, chatIdStr, chatIdNum, locale, parsed, accounts, categories, mainCurrency, deps, 0);
}

export async function handleAppVoiceBytes(
  uid: string,
  chatIdStr: string,
  chatIdNum: number,
  bytes: Buffer,
  deps: TelegramHandleDeps,
  sink: AppAgentSink
): Promise<void> {
  const prefs = await loadAgentPreferences(deps.db, uid);
  const locale = pickBotLocale({ localeOverride: prefs.localeOverride });
  await sink.onStatus(AgentStatusKeys.transcribing);
  const accounts = await loadAccountsForBot(deps.db, uid);
  const categories = await loadCategoriesForBot(deps.db, uid);
  const mainCurrency = await loadMainCurrency(deps.db, uid);
  const genkitToolContext = { db: deps.db, uid };
  await sink.onStatus(AgentStatusKeys.understanding);
  const parsed = await parseVoiceBytesWithOptionalGemini(
    deps.geminiApiKey,
    mainCurrency,
    bytes,
    "audio/ogg",
    categories,
    accounts,
    locale,
    genkitToolContext
  );
  if (!parsed || parsed.amountMinor == null || parsed.amountMinor <= 0) {
    await sink.markFailed("agentError.media");
    return;
  }
  const locale2 = pickBotLocale({
    localeOverride: prefs.localeOverride,
    userText: parsed.memo,
  });
  await beginSpendFlow(
    uid,
    chatIdStr,
    chatIdNum,
    locale2,
    parsed,
    accounts,
    categories,
    mainCurrency,
    deps,
    0
  );
}
