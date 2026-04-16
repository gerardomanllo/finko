import { DateTime } from "luxon";

/**
 * Calendar `yyyy-MM-dd` for “today” in the user’s IANA timezone when set on
 * `users/{uid}.timezone`; otherwise Luxon’s system zone (matches `resolveAsOfYmd`
 * in `scheduleNext.ts`).
 */
export function getUserTodayYmd(userData: Record<string, unknown> | undefined): string {
  const tzRaw = userData?.timezone;
  const tz = typeof tzRaw === "string" && tzRaw.trim().length > 0 ? tzRaw.trim() : "";
  if (tz) {
    const now = DateTime.now().setZone(tz);
    if (now.isValid) {
      return now.toISODate()!;
    }
  }
  return DateTime.now().toISODate()!;
}

/**
 * When `true`, ledger aggregates (balances, `monthlyTotals`) should include this
 * posting date. Future calendar dates (strictly after [todayYmd]) are excluded.
 *
 * Malformed date strings: fail open (include) so bad data does not silently skip money.
 */
export function isLedgerDateEffectiveForAggregate(
  transactionYmd: string,
  todayYmd: string
): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(transactionYmd)) {
    return true;
  }
  const d = DateTime.fromISO(transactionYmd, { zone: "utc" });
  if (!d.isValid) {
    return true;
  }
  return transactionYmd <= todayYmd;
}
