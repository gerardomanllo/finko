import { DateTime } from "luxon";

/** Defaults for `commitRecurringFromLedgerTransaction` from posted tx calendar day. */
export function recurringScheduleDefaults(
  txDateYmd: string,
  cadence: string
): { daysOfMonth: number[]; weekday: number | null } {
  const dt = DateTime.fromISO(txDateYmd, { zone: "utc" });
  if (!dt.isValid) {
    return { daysOfMonth: [1], weekday: null };
  }
  const dom = dt.day;
  const wk = dt.weekday;
  switch (cadence) {
    case "monthly":
      return { daysOfMonth: [dom], weekday: null };
    case "twiceMonthly": {
      const second = dom <= 14 ? Math.min(dom + 14, 28) : Math.max(dom - 14, 1);
      let a = Math.min(dom, second);
      let b = Math.max(dom, second);
      if (a === b) {
        b = Math.min(28, a + 7);
      }
      return { daysOfMonth: [a, b].sort((x, y) => x - y), weekday: null };
    }
    case "weekly":
      return { daysOfMonth: [], weekday: wk };
    case "biweekly":
      return { daysOfMonth: [], weekday: null };
    default:
      return { daysOfMonth: [], weekday: null };
  }
}
