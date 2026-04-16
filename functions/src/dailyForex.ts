import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";

import {
  FINKO_FX_CURRENCIES,
  FINKO_MAIN_CURRENCY,
  filterFrankfurterRatesToTri,
} from "./forex";

/**
 * Daily ingest: **only** USD and EUR vs MXN (Frankfurter `from=MXN`).
 * Cross-rates USD↔EUR use MXN as hub ([`convertMinorBetweenUsdMxnEur`] in `forex.ts`).
 */
export const ingestDailyForexRates = onSchedule(
  {
    schedule: "every day 08:00",
    timeZone: "UTC",
    region: "us-central1",
  },
  async () => {
    const db = getFirestore();
    const today = new Date().toISOString().slice(0, 10);
    const url = `https://api.frankfurter.dev/v1/${today}?from=${FINKO_MAIN_CURRENCY}`;
    const res = await fetch(url);
    if (!res.ok) {
      logger.error("Frankfurter request failed", res.status, await res.text());
      return;
    }
    const body = (await res.json()) as {
      base: string;
      rates: Record<string, number>;
    };
    let tri: { base: typeof FINKO_MAIN_CURRENCY; rates: { USD: number; EUR: number } };
    try {
      tri = filterFrankfurterRatesToTri(body);
    } catch (e) {
      logger.error("Tri-currency filter failed", e);
      return;
    }
    await db.doc(`forexRates/${today}`).set({
      date: today,
      base: tri.base,
      rates: tri.rates,
      /** Document which ISO codes are supported for this product. */
      currenciesSupported: [...FINKO_FX_CURRENCIES],
      updatedAt: FieldValue.serverTimestamp(),
    });
    logger.info("Stored forexRates (USD/EUR vs MXN)", today, tri.rates);
  }
);
