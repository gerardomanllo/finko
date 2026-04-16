import type { Firestore } from "firebase-admin/firestore";

/** Product hub currency; Frankfurter quotes are requested with `from=MXN`. */
export const FINKO_MAIN_CURRENCY = "MXN";

/** Currencies we ingest and support for cross-rates (hub = MXN). */
export const FINKO_FX_CURRENCIES = ["MXN", "USD", "EUR"] as const;
export type FinkoFxCurrency = (typeof FINKO_FX_CURRENCIES)[number];

/**
 * Stored under `forexRates/{date}`: `rates.USD` and `rates.EUR` are **quote
 * currency per 1 MXN** (major units), matching Frankfurter `from=MXN`.
 */
export type MxnHubRates = { USD: number; EUR: number };

/** Keep only USD/MXN/EUR quotes; MXN is implicit (base). */
export function filterFrankfurterRatesToTri(body: {
  base: string;
  rates: Record<string, number>;
}): { base: typeof FINKO_MAIN_CURRENCY; rates: MxnHubRates } {
  if (body.base !== FINKO_MAIN_CURRENCY) {
    throw new Error(
      `Expected Frankfurter base ${FINKO_MAIN_CURRENCY}, got ${body.base}`
    );
  }
  const usd = body.rates.USD;
  const eur = body.rates.EUR;
  if (usd === undefined || eur === undefined) {
    throw new Error("Frankfurter response missing USD or EUR vs MXN");
  }
  if (usd <= 0 || eur <= 0) {
    throw new Error(`Invalid USD/EUR quotes vs MXN: USD=${usd} EUR=${eur}`);
  }
  return {
    base: FINKO_MAIN_CURRENCY,
    rates: { USD: usd, EUR: eur },
  };
}

/**
 * Convert between any of MXN / USD / EUR using MXN as the hub (same basis as
 * [`foreignMinorToMainMinor`] when main is MXN).
 */
export function convertMinorBetweenUsdMxnEur(
  amountMinor: number,
  from: string,
  to: string,
  rates: MxnHubRates
): number {
  const f = from.toUpperCase();
  const t = to.toUpperCase();
  if (f === t) return amountMinor;

  const allowed = new Set<string>(FINKO_FX_CURRENCIES);
  if (!allowed.has(f) || !allowed.has(t)) {
    throw new Error(
      `Unsupported currency: only ${FINKO_FX_CURRENCIES.join(", ")} (got ${from} → ${to})`
    );
  }

  const mxnMinor = foreignMinorToMxnMinor(amountMinor, f, rates);
  return mxnMinorToForeignMinor(mxnMinor, t, rates);
}

function foreignMinorToMxnMinor(
  amountMinor: number,
  foreign: string,
  rates: MxnHubRates
): number {
  if (foreign === FINKO_MAIN_CURRENCY) return amountMinor;
  const r = foreign === "USD" ? rates.USD : rates.EUR;
  const foreignMajor = amountMinor / 100;
  const mxnMajor = foreignMajor / r;
  return Math.round(mxnMajor * 100);
}

function mxnMinorToForeignMinor(
  mxnMinor: number,
  to: string,
  rates: MxnHubRates
): number {
  if (to === FINKO_MAIN_CURRENCY) return mxnMinor;
  const r = to === "USD" ? rates.USD : rates.EUR;
  const mxnMajor = mxnMinor / 100;
  const foreignMajor = mxnMajor * r;
  return Math.round(foreignMajor * 100);
}

/** Walk backward from [startYyyyMmDd] until a `forexRates/{date}` doc exists. */
export async function findForexDocWalkBack(
  db: Firestore,
  startYyyyMmDd: string,
  maxDays = 14
): Promise<{ dateKey: string; rates: MxnHubRates } | null> {
  let cur = parseYmd(startYyyyMmDd);
  for (let i = 0; i < maxDays; i++) {
    const key = formatYmd(cur);
    const snap = await db.doc(`forexRates/${key}`).get();
    if (snap.exists) {
      const data = snap.data() ?? {};
      const raw = data.rates;
      const rates = parseMxnHubRates(raw);
      if (rates) {
        return { dateKey: key, rates };
      }
    }
    cur = addDays(cur, -1);
  }
  return null;
}

function parseMxnHubRates(raw: unknown): MxnHubRates | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const usd = o.USD;
  const eur = o.EUR;
  if (typeof usd !== "number" || typeof eur !== "number") return null;
  if (usd <= 0 || eur <= 0) return null;
  return { USD: usd, EUR: eur };
}

/**
 * Convert **foreign minor** → **main minor** when main is MXN and `rates` is
 * [`MxnHubRates`] (USD/EUR per 1 MXN).
 */
export function foreignMinorToMainMinor(
  amountMinor: number,
  foreign: string,
  mainCurrency: string,
  ratesPerMain: Record<string, number>
): number {
  if (foreign === mainCurrency) return amountMinor;
  const r = ratesPerMain[foreign];
  if (r === undefined || r === 0) {
    throw new Error(`Missing FX rate for ${foreign} (main=${mainCurrency})`);
  }
  const foreignMajor = amountMinor / 100;
  const mainMajor = foreignMajor / r;
  return Math.round(mainMajor * 100);
}

function parseYmd(s: string): { y: number; m: number; d: number } {
  const [y, m, d] = s.split("-").map((x) => Number(x));
  return { y, m, d };
}

function formatYmd(p: { y: number; m: number; d: number }): string {
  return `${String(p.y).padStart(4, "0")}-${String(p.m).padStart(2, "0")}-${String(p.d).padStart(2, "0")}`;
}

function addDays(p: { y: number; m: number; d: number }, delta: number): {
  y: number;
  m: number;
  d: number;
} {
  const dt = new Date(Date.UTC(p.y, p.m - 1, p.d + delta));
  return { y: dt.getUTCFullYear(), m: dt.getUTCMonth() + 1, d: dt.getUTCDate() };
}
