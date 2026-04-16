import { DateTime } from "luxon";

/** Gregorian length; [month] is 1–12. */
export function daysInMonth(year: number, month: number): number {
  return DateTime.utc(year, month, 1).daysInMonth ?? 31;
}

export function clampDayInMonth(year: number, month: number, day: number): number {
  const dim = daysInMonth(year, month);
  return Math.min(day, dim);
}

/**
 * Next scheduled `yyyy-MM-dd` after a post on [postedYmd], using the same fields as
 * `upcomingTransactions` / `recurring` (see onboarding validation + EOM rule).
 */
export function computeNextTransactionDate(
  postedYmd: string,
  u: {
    cadence?: string | null;
    daysOfMonth?: number[] | null;
    weekday?: number | null;
  }
): string | null {
  const c = u.cadence ?? undefined;
  const dom = (u.daysOfMonth ?? [])
    .filter((n) => typeof n === "number" && n >= 1 && n <= 31)
    .sort((a, b) => a - b);
  const wk = typeof u.weekday === "number" ? u.weekday : null;

  const posted = DateTime.fromISO(postedYmd, { zone: "utc" });
  if (!posted.isValid) {
    return null;
  }

  if (c === "monthly" && dom.length >= 1) {
    const anchor = dom[0];
    let y = posted.year;
    let m = posted.month + 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    const d = clampDayInMonth(y, m, anchor);
    return DateTime.utc(y, m, d).toISODate()!;
  }

  if (c === "twiceMonthly" && dom.length >= 2) {
    const anchors = [...new Set(dom)].sort((a, b) => a - b);
    const dayNum = posted.day;
    const nextAfter = anchors.find((a) => a > dayNum);
    if (nextAfter !== undefined) {
      const y = posted.year;
      const m = posted.month;
      const d = clampDayInMonth(y, m, nextAfter);
      return DateTime.utc(y, m, d).toISODate()!;
    }
    const first = anchors[0];
    let y = posted.year;
    let m = posted.month + 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    const d = clampDayInMonth(y, m, first);
    return DateTime.utc(y, m, d).toISODate()!;
  }

  if (c === "biweekly") {
    return posted.plus({ days: 14 }).toISODate()!;
  }

  if (c === "weekly" && wk !== null && wk >= 1 && wk <= 7) {
    let cursor = posted.startOf("day").plus({ days: 1 });
    for (let i = 0; i < 400; i++) {
      if (cursor.weekday === wk) {
        return cursor.toISODate()!;
      }
      cursor = cursor.plus({ days: 1 });
    }
    return null;
  }

  return null;
}

/** Callable payload: explicit date wins, else IANA zone for “today”, else local server calendar day. */
export function resolveAsOfYmd(payload: { asOfDate?: unknown; timezone?: unknown }): string {
  if (typeof payload.asOfDate === "string" && /^\d{4}-\d{2}-\d{2}$/.test(payload.asOfDate)) {
    return payload.asOfDate;
  }
  const tz = typeof payload.timezone === "string" && payload.timezone.trim().length > 0 ? payload.timezone.trim() : "";
  if (tz) {
    const now = DateTime.now().setZone(tz);
    if (now.isValid) {
      return now.toISODate()!;
    }
  }
  return DateTime.now().toISODate()!;
}
