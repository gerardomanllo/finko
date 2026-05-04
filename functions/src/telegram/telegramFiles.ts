/** Download a file acquired via `getFile` (voice, photo, etc.). */

export async function telegramGetFilePath(
  fetchFn: typeof fetch,
  botToken: string,
  fileId: string
): Promise<string | null> {
  const url = `https://api.telegram.org/bot${botToken}/getFile?file_id=${encodeURIComponent(fileId)}`;
  const res = await fetchFn(url);
  const json = (await res.json()) as {
    ok?: boolean;
    result?: { file_path?: string };
  };
  if (!json.ok || typeof json.result?.file_path !== "string") {
    return null;
  }
  return json.result.file_path;
}

export async function telegramDownloadFileBytes(
  fetchFn: typeof fetch,
  botToken: string,
  filePath: string
): Promise<Buffer | null> {
  const url = `https://api.telegram.org/file/bot${botToken}/${filePath}`;
  const res = await fetchFn(url);
  if (!res.ok) return null;
  const ab = await res.arrayBuffer();
  return Buffer.from(ab);
}
