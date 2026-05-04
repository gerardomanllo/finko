import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { commitRecurringFromLedgerTransaction } from "./recurringFromLedgerTx";

type JsonMap = Record<string, unknown>;

function mustString(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${name} is required.`);
  }
  return value.trim();
}

/**
 * Creates `recurring` + one `upcomingTransactions` row from an existing ledger
 * transaction (standard, non–transfer-leg). KB-001 MVP.
 */
export const createRecurringFromTransaction = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();
  const data = (request.data ?? {}) as JsonMap;

  const transactionId = mustString(data.transactionId, "transactionId");
  const cadence = mustString(data.cadence, "cadence").toLowerCase();

  const rawDays = Array.isArray(data.daysOfMonth) ? (data.daysOfMonth as unknown[]) : [];
  const daysOfMonth = rawDays
    .map((x) => Number(x))
    .filter((n) => Number.isFinite(n) && n >= 1 && n <= 31);
  const weekday = typeof data.weekday === "number" && data.weekday >= 1 && data.weekday <= 7 ? data.weekday : null;

  const timezone = typeof data.timezone === "string" ? data.timezone.trim() : "";
  const nameRaw = data.name;

  try {
    return await commitRecurringFromLedgerTransaction(db, uid, {
      transactionId,
      cadence,
      daysOfMonth,
      weekday,
      timezone: timezone.length > 0 ? timezone : undefined,
      name: typeof nameRaw === "string" ? nameRaw : undefined,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg === "invalid cadence") {
      throw new HttpsError(
        "invalid-argument",
        "cadence must be monthly, twiceMonthly, biweekly, or weekly."
      );
    }
    if (msg === "daysOfMonth required") {
      throw new HttpsError("invalid-argument", "daysOfMonth is required for monthly / twiceMonthly.");
    }
    if (msg === "twiceMonthly needs two days") {
      throw new HttpsError("invalid-argument", "twiceMonthly requires at least two daysOfMonth.");
    }
    if (msg === "weekday required") {
      throw new HttpsError("invalid-argument", "weekday (1–7) is required for weekly cadence.");
    }
    if (msg === "transaction not found") {
      throw new HttpsError("not-found", "Transaction not found.");
    }
    if (msg === "cannot recurring from transfer leg") {
      throw new HttpsError("failed-precondition", "Cannot create a recurring rule from a transfer leg.");
    }
    if (msg === "cannot recurring from adjustment") {
      throw new HttpsError("failed-precondition", "Cannot create a recurring rule from an adjustment.");
    }
    if (msg === "amount must be positive") {
      throw new HttpsError("invalid-argument", "Transaction amount must be positive.");
    }
    if (msg === "missing account or category") {
      throw new HttpsError("invalid-argument", "Transaction is missing accountId or categoryId.");
    }
    if (msg === "bad transactionDate") {
      throw new HttpsError("invalid-argument", "Transaction has invalid transactionDate.");
    }
    throw new HttpsError("internal", msg || "recurring failed");
  }
});
