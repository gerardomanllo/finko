export function normalizeTelegramUsername(raw: string): string {
  const t = raw.trim();
  if (t.length < 2) {
    return "";
  }
  const noAt = t.startsWith("@") ? t.slice(1) : t;
  return noAt.toLowerCase();
}

export function isLikelyTelegramUsername(s: string): boolean {
  const n = normalizeTelegramUsername(s);
  return n.length >= 5 && /^[a-z][a-z0-9_]{4,}$/.test(n);
}

/** E.164-style: + then 7–15 digits (ITU-T E.164 max). */
export function isLikelyE164(raw: string): boolean {
  const s = raw.trim();
  return /^\+[1-9]\d{6,14}$/.test(s);
}
