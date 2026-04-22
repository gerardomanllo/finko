export type TelegramSendResult = { ok: true } | { ok: false; description: string };

export async function telegramSendMessage(
  botToken: string,
  chatId: string | number,
  text: string
): Promise<TelegramSendResult> {
  const url = `https://api.telegram.org/bot${botToken}/sendMessage`;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      chat_id: chatId,
      text,
      disable_web_page_preview: true,
    }),
  });
  const body = (await res.json()) as { ok?: boolean; description?: string };
  if (!res.ok || body.ok !== true) {
    return { ok: false, description: body.description ?? `http_${res.status}` };
  }
  return { ok: true };
}
