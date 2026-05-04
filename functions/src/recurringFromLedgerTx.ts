import { FieldValue, Firestore } from "firebase-admin/firestore";

import { computeNextTransactionDate, resolveAsOfYmd } from "./scheduleNext";
import { touchLedgerSourcesLastChangedAt } from "./userLedgerSync";

type JsonMap = Record<string, unknown>;

function firstUpcomingOnOrAfterAsOf(
  anchorYmd: string,
  asOfYmd: string,
  sched: { cadence: string; daysOfMonth: number[]; weekday: number | null }
): string {
  let cur = anchorYmd;
  for (let i = 0; i < 400; i++) {
    const next = computeNextTransactionDate(cur, sched);
    if (next === null) {
      throw new Error("Could not compute next occurrence for this cadence.");
    }
    if (next >= asOfYmd) {
      return next;
    }
    cur = next;
  }
  throw new Error("Schedule produced no upcoming date within range.");
}

export type CommitRecurringInput = {
  transactionId: string;
  cadence: string;
  daysOfMonth: number[];
  weekday: number | null;
  timezone?: string;
  name?: string;
};

/**
 * Shared DB write used by `createRecurringFromTransaction` callable and Telegram bot.
 * Throws Error with message suitable for logs if validation fails.
 */
export async function commitRecurringFromLedgerTransaction(
  db: Firestore,
  uid: string,
  input: CommitRecurringInput
): Promise<{ recurringRuleId: string; upcomingId: string; nextTransactionDate: string }> {
  const cadence = input.cadence.toLowerCase();
  const allowed = new Set(["monthly", "twiceMonthly", "biweekly", "weekly"]);
  if (!allowed.has(cadence)) {
    throw new Error("invalid cadence");
  }

  const daysOfMonth = input.daysOfMonth.filter((n) => Number.isFinite(n) && n >= 1 && n <= 31);
  const weekday =
    typeof input.weekday === "number" && input.weekday >= 1 && input.weekday <= 7
      ? input.weekday
      : null;

  if ((cadence === "monthly" || cadence === "twiceMonthly") && daysOfMonth.length === 0) {
    throw new Error("daysOfMonth required");
  }
  if (cadence === "twiceMonthly" && daysOfMonth.length < 2) {
    throw new Error("twiceMonthly needs two days");
  }
  if (cadence === "weekly" && weekday === null) {
    throw new Error("weekday required");
  }

  const txRef = db.doc(`users/${uid}/transactions/${input.transactionId}`);
  const txSnap = await txRef.get();
  if (!txSnap.exists) {
    throw new Error("transaction not found");
  }
  const tx = txSnap.data() as JsonMap;
  const typ = typeof tx.type === "string" ? tx.type : "standard";
  if (typ === "transferLeg") {
    throw new Error("cannot recurring from transfer leg");
  }
  if (typ === "adjustment") {
    throw new Error("cannot recurring from adjustment");
  }

  const amountMinor = typeof tx.amountMinor === "number" ? Math.trunc(tx.amountMinor) : 0;
  if (amountMinor <= 0) {
    throw new Error("amount must be positive");
  }
  const direction = tx.direction === "in" || tx.direction === "out" ? tx.direction : "out";
  const currency =
    typeof tx.currency === "string" && tx.currency.trim().length > 0 ? tx.currency.trim().toUpperCase() : "MXN";
  const accountId = typeof tx.accountId === "string" ? tx.accountId.trim() : "";
  const categoryId = typeof tx.categoryId === "string" ? tx.categoryId.trim() : "";
  if (!accountId || !categoryId) {
    throw new Error("missing account or category");
  }

  const txDate = typeof tx.transactionDate === "string" ? tx.transactionDate.trim() : "";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(txDate)) {
    throw new Error("bad transactionDate");
  }

  const asOfYmd = resolveAsOfYmd({ timezone: input.timezone });

  const sched = {
    cadence,
    daysOfMonth: cadence === "weekly" || cadence === "biweekly" ? [] : daysOfMonth,
    weekday: cadence === "weekly" ? weekday : null,
  };

  const nextTransactionDate = firstUpcomingOnOrAfterAsOf(txDate, asOfYmd, sched);

  const name =
    typeof input.name === "string" && input.name.trim().length > 0
      ? input.name.trim().slice(0, 120)
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
}
