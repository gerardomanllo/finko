import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { computeNextTransactionDate, resolveAsOfYmd } from "./scheduleNext";
import { touchLedgerSourcesLastChangedAt } from "./userLedgerSync";

type JsonMap = Record<string, unknown>;

function mustString(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${name} is required.`);
  }
  return value.trim();
}

function firstUpcomingOnOrAfterAsOf(
  anchorYmd: string,
  asOfYmd: string,
  sched: { cadence: string; daysOfMonth: number[]; weekday: number | null }
): string {
  let cur = anchorYmd;
  for (let i = 0; i < 400; i++) {
    const next = computeNextTransactionDate(cur, sched);
    if (next === null) {
      throw new HttpsError("invalid-argument", "Could not compute next occurrence for this cadence.");
    }
    if (next >= asOfYmd) {
      return next;
    }
    cur = next;
  }
  throw new HttpsError("invalid-argument", "Schedule produced no upcoming date within range.");
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
  const allowed = new Set(["monthly", "twiceMonthly", "biweekly", "weekly"]);
  if (!allowed.has(cadence)) {
    throw new HttpsError("invalid-argument", "cadence must be monthly, twiceMonthly, biweekly, or weekly.");
  }

  const rawDays = Array.isArray(data.daysOfMonth) ? (data.daysOfMonth as unknown[]) : [];
  const daysOfMonth = rawDays
    .map((x) => Number(x))
    .filter((n) => Number.isFinite(n) && n >= 1 && n <= 31);
  const weekday = typeof data.weekday === "number" && data.weekday >= 1 && data.weekday <= 7 ? data.weekday : null;

  if ((cadence === "monthly" || cadence === "twiceMonthly") && daysOfMonth.length === 0) {
    throw new HttpsError("invalid-argument", "daysOfMonth is required for monthly / twiceMonthly.");
  }
  if (cadence === "twiceMonthly" && daysOfMonth.length < 2) {
    throw new HttpsError("invalid-argument", "twiceMonthly requires at least two daysOfMonth.");
  }
  if (cadence === "weekly" && weekday === null) {
    throw new HttpsError("invalid-argument", "weekday (1–7) is required for weekly cadence.");
  }

  const txRef = db.doc(`users/${uid}/transactions/${transactionId}`);
  const txSnap = await txRef.get();
  if (!txSnap.exists) {
    throw new HttpsError("not-found", "Transaction not found.");
  }
  const tx = txSnap.data() as JsonMap;
  const typ = typeof tx.type === "string" ? tx.type : "standard";
  if (typ === "transferLeg") {
    throw new HttpsError("failed-precondition", "Cannot create a recurring rule from a transfer leg.");
  }
  if (typ === "adjustment") {
    throw new HttpsError("failed-precondition", "Cannot create a recurring rule from an adjustment.");
  }

  const amountMinor = typeof tx.amountMinor === "number" ? Math.trunc(tx.amountMinor) : 0;
  if (amountMinor <= 0) {
    throw new HttpsError("invalid-argument", "Transaction amount must be positive.");
  }
  const direction = tx.direction === "in" || tx.direction === "out" ? tx.direction : "out";
  const currency = typeof tx.currency === "string" && tx.currency.trim().length > 0 ? tx.currency.trim().toUpperCase() : "MXN";
  const accountId = typeof tx.accountId === "string" ? tx.accountId.trim() : "";
  const categoryId = typeof tx.categoryId === "string" ? tx.categoryId.trim() : "";
  if (!accountId) {
    throw new HttpsError("invalid-argument", "Transaction is missing accountId.");
  }
  if (!categoryId) {
    throw new HttpsError("invalid-argument", "Transaction is missing categoryId.");
  }

  const txDate = typeof tx.transactionDate === "string" ? tx.transactionDate.trim() : "";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(txDate)) {
    throw new HttpsError("invalid-argument", "Transaction has invalid transactionDate.");
  }

  const timezone = typeof data.timezone === "string" ? data.timezone.trim() : "";
  const asOfYmd = resolveAsOfYmd({ timezone: timezone.length > 0 ? timezone : undefined });

  const sched = {
    cadence,
    daysOfMonth: cadence === "weekly" || cadence === "biweekly" ? [] : daysOfMonth,
    weekday: cadence === "weekly" ? weekday : null,
  };

  const nextTransactionDate = firstUpcomingOnOrAfterAsOf(txDate, asOfYmd, sched);

  const nameRaw = data.name;
  const name =
    typeof nameRaw === "string" && nameRaw.trim().length > 0
      ? nameRaw.trim().slice(0, 120)
      : "Recurring";

  const memo = typeof tx.memo === "string" ? tx.memo : null;

  const ruleRef = db.collection(`users/${uid}/recurring`).doc();
  const upcomingRef = db.collection(`users/${uid}/upcomingTransactions`).doc();

  const batch = db.batch();
  batch.set(ruleRef, {
    name,
    kind: "standard",
    amountMinor,
    direction,
    currency,
    categoryId,
    accountId,
    memo,
    cadence,
    daysOfMonth: sched.daysOfMonth,
    weekday: sched.weekday,
    active: true,
    nextTransactionDate,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  batch.set(upcomingRef, {
    transactionDate: nextTransactionDate,
    kind: "standard",
    amountMinor,
    direction,
    currency,
    accountId,
    categoryId,
    memo,
    cadence,
    daysOfMonth: sched.daysOfMonth,
    weekday: sched.weekday,
    recurringRuleId: ruleRef.id,
    loadedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
  await touchLedgerSourcesLastChangedAt(db, uid);

  return { recurringRuleId: ruleRef.id, upcomingId: upcomingRef.id, nextTransactionDate };
});
