/** Helpers for Telegram Bot API HTTP calls (inject fetch for tests). */

export type TelegramHttpResponse = { ok: boolean; description?: string };

export async function telegramPostJson(
  fetchFn: typeof fetch,
  botToken: string,
  method: string,
  body: Record<string, unknown>
): Promise<{ httpOk: boolean; json: TelegramHttpResponse & Record<string, unknown> }> {
  const url = `https://api.telegram.org/bot${botToken}/${method}`;
  const res = await fetchFn(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const json = (await res.json()) as TelegramHttpResponse & Record<string, unknown>;
  return { httpOk: res.ok, json };
}

export async function telegramSendMessage(
  fetchFn: typeof fetch,
  botToken: string,
  chatId: number,
  text: string,
  extra?: { reply_markup?: unknown }
): Promise<boolean> {
  const payload: Record<string, unknown> = {
    chat_id: chatId,
    text,
    disable_web_page_preview: true,
    ...extra,
  };
  const { httpOk, json } = await telegramPostJson(fetchFn, botToken, "sendMessage", payload);
  return httpOk && json.ok === true;
}

export async function telegramAnswerCallbackQuery(
  fetchFn: typeof fetch,
  botToken: string,
  callbackQueryId: string,
  options?: { text?: string; show_alert?: boolean }
): Promise<boolean> {
  const payload: Record<string, unknown> = {
    callback_query_id: callbackQueryId,
    ...options,
  };
  const { httpOk, json } = await telegramPostJson(fetchFn, botToken, "answerCallbackQuery", payload);
  return httpOk && json.ok === true;
}

export async function telegramEditMessageText(
  fetchFn: typeof fetch,
  botToken: string,
  chatId: number,
  messageId: number,
  text: string,
  extra?: { reply_markup?: unknown }
): Promise<boolean> {
  const payload: Record<string, unknown> = {
    chat_id: chatId,
    message_id: messageId,
    text,
    disable_web_page_preview: true,
    ...extra,
  };
  const { httpOk, json } = await telegramPostJson(fetchFn, botToken, "editMessageText", payload);
  return httpOk && json.ok === true;
}
