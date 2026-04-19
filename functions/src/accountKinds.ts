/**
 * Account type classification for ledger balance polarity (see docs/data-model.md).
 * Liability: positive balance = amount owed.
 */

const LIABILITY_TYPES = new Set(["creditCard", "loan", "mortgage"]);

export function isLiabilityAccountType(raw: string | undefined): boolean {
  if (raw == null || typeof raw !== "string") return false;
  return LIABILITY_TYPES.has(raw.trim());
}

/** Opening-balance adjustment direction (see Dart `openingBalanceDirectionForAccount`). */
export function openingBalanceDirectionForAccount(
  accountType: string | undefined,
  startingBalanceMinor: number
): "in" | "out" {
  if (startingBalanceMinor >= 0) {
    return isLiabilityAccountType(accountType) ? "out" : "in";
  }
  return isLiabilityAccountType(accountType) ? "in" : "out";
}
