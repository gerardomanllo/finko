/**
 * Heuristic parse for `50 coffee`, `+100 salary`, localized decimals.
 * Amount is minor units (main currency, 2 decimal places).
 */
export type ParsedUserSpend = {
  amountMinor: number;
  memo: string;
  direction: "in" | "out";
};

export function parseSpendLine(mainCurrency: string, raw: string): ParsedUserSpend | null {
  void mainCurrency;
  const line = raw.trim();
  if (line.length === 0) return null;

  let direction: "in" | "out" = "out";
  let numPart = line;
  if (numPart.startsWith("+")) {
    direction = "in";
    numPart = numPart.slice(1).trim();
  }

  const re = /^([\d]{1,12})(?:[.,](\d{0,2}))?\s*(.*)$/s;
  const m = re.exec(numPart);
  if (!m) return null;

  const whole = m[1] ?? "";
  const fracRaw = m[2] ?? "";
  const frac = fracRaw.length === 0 ? "00" : fracRaw.padEnd(2, "0").slice(0, 2);
  const memo = (m[3] ?? "").trim();

  const amountMajor = Number(`${whole}.${frac}`);
  if (!Number.isFinite(amountMajor) || amountMajor <= 0) return null;

  return {
    amountMinor: Math.round(amountMajor * 100),
    memo: memo.length > 0 ? memo : direction === "in" ? "Income" : "Expense",
    direction,
  };
}

export function truncateForTelegram(s: string, max = 3500): string {
  if (s.length <= max) return s;
  return `${s.slice(0, max - 1)}…`;
}
