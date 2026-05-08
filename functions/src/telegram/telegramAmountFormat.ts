/**
 * User-visible money for Telegram copy: ISO currency + thousands + 2 decimals.
 * Example: `MXN $1,234.56`, `USD $10.00`.
 */
export function formatLedgerAmountMinor(amountMinor: number, currencyCode: string): string {
  const ccy = (currencyCode ?? "").trim().toUpperCase();
  const iso = ccy.length > 0 ? ccy : "MXN";
  const major = amountMinor / 100;
  const num = new Intl.NumberFormat("en-US", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(major);
  return `${iso} $${num}`;
}
