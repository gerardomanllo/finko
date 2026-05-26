import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import { computeNextTransactionDate, resolveAsOfYmd } from "./scheduleNext";

const LEDGER_TRANSFER_CATEGORY_ID = "ledger-transfer";

/** Stable ids so concurrent / retried materialization cannot create duplicate legs. */
function materializedStandardTxId(upcomingId: string, transactionDateYyyyMmDd: string): string {
  const d = transactionDateYyyyMmDd.replace(/-/g, "");
  return `mat_${upcomingId}_${d}`;
}

function materializedTransferLegIds(
  upcomingId: string,
  transactionDateYyyyMmDd: string
): { outId: string; inId: string } {
  const d = transactionDateYyyyMmDd.replace(/-/g, "");
  return { outId: `mat_${upcomingId}_${d}_out`, inId: `mat_${upcomingId}_${d}_in` };
}

export const materializeDueUpcoming = onCall({ region: "us-central1" }, async (request) => {
  const db = getFirestore();
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.data?.uid as string | undefined;
  if (!uid || uid !== request.auth.uid) {
    throw new HttpsError("permission-denied", "UID mismatch.");
  }
  const asOfDate = resolveAsOfYmd({
    asOfDate: request.data?.asOfDate,
    timezone: request.data?.timezone,
  });

  const snap = await db
    .collection(`users/${uid}/upcomingTransactions`)
    .where("transactionDate", "<=", asOfDate)
    .orderBy("transactionDate", "asc")
    .get();

  if (snap.empty) {
    return { processed: 0 };
  }

  let processed = 0;
  let batch = db.batch();
  let ops = 0;

  const commitIfNeeded = async (force = false) => {
    if (ops === 0) return;
    if (ops >= 400 || force) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  };

  for (const doc of snap.docs) {
    const u = doc.data();
    const kind = u.kind as string;
    const upcomingId = doc.id;
    const recurringRuleId = typeof u.recurringRuleId === "string" ? u.recurringRuleId : undefined;

    if (kind === "standard") {
      const categoryId =
        typeof u.categoryId === "string" && u.categoryId.trim().length > 0
          ? u.categoryId.trim()
          : null;
      if (!categoryId) {
        logger.warn("materialize: skipping upcoming without categoryId", {
          uid,
          upcomingId,
        });
        continue;
      }
      const ymdStd = u.transactionDate as string;
      const txRef = db
        .collection(`users/${uid}/transactions`)
        .doc(materializedStandardTxId(upcomingId, ymdStd));
      batch.set(txRef, {
        transactionDate: u.transactionDate,
        loadedAt: FieldValue.serverTimestamp(),
        amountMinor: u.amountMinor,
        direction: u.direction,
        currency: u.currency,
        accountId: u.accountId,
        categoryId,
        type: "standard",
        memo: u.memo ?? null,
        sourceUpcomingId: upcomingId,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      ops++;
    } else if (kind === "transfer") {
      const fromId = u.fromAccountId as string;
      const toId = u.toAccountId as string;
      const ymdTr = u.transactionDate as string;
      const { outId, inId } = materializedTransferLegIds(upcomingId, ymdTr);
      const gid = u.transferGroupId ?? `matgrp_${upcomingId}_${ymdTr.replace(/-/g, "")}`;
      const outRef = db.collection(`users/${uid}/transactions`).doc(outId);
      const inRef = db.collection(`users/${uid}/transactions`).doc(inId);
      batch.set(outRef, {
        transactionDate: u.transactionDate,
        loadedAt: FieldValue.serverTimestamp(),
        amountMinor: u.amountMinor,
        direction: "out",
        currency: u.currency,
        accountId: fromId,
        categoryId: LEDGER_TRANSFER_CATEGORY_ID,
        type: "transferLeg",
        memo: u.memo ?? null,
        transferGroupId: gid,
        linkedTransactionId: inRef.id,
        sourceUpcomingId: upcomingId,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      batch.set(inRef, {
        transactionDate: u.transactionDate,
        loadedAt: FieldValue.serverTimestamp(),
        amountMinor: u.amountMinor,
        direction: "in",
        currency: u.currency,
        accountId: toId,
        categoryId: LEDGER_TRANSFER_CATEGORY_ID,
        type: "transferLeg",
        memo: u.memo ?? null,
        transferGroupId: gid,
        linkedTransactionId: outRef.id,
        sourceUpcomingId: upcomingId,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      ops += 2;
    } else {
      logger.warn("Skipping unknown upcoming kind", kind, upcomingId);
      continue;
    }

    const ymd = u.transactionDate as string;
    const daysOfMonth = Array.isArray(u.daysOfMonth)
      ? (u.daysOfMonth as unknown[]).map((x) => Number(x)).filter((n) => Number.isFinite(n) && n >= 1 && n <= 31)
      : [];
    const weekday = typeof u.weekday === "number" ? u.weekday : null;
    const cadence = typeof u.cadence === "string" ? u.cadence : undefined;

    const nextDate = computeNextTransactionDate(ymd, {
      cadence,
      daysOfMonth,
      weekday,
    });

    if (nextDate != null) {
      batch.update(doc.ref, {
        transactionDate: nextDate,
        updatedAt: FieldValue.serverTimestamp(),
      });
      ops++;
      if (recurringRuleId) {
        batch.update(db.doc(`users/${uid}/recurring/${recurringRuleId}`), {
          nextTransactionDate: nextDate,
          updatedAt: FieldValue.serverTimestamp(),
        });
        ops++;
      }
    } else {
      batch.delete(doc.ref);
      ops++;
      if (recurringRuleId) {
        batch.delete(db.doc(`users/${uid}/recurring/${recurringRuleId}`));
        ops++;
      }
    }

    processed++;
    await commitIfNeeded();
  }

  await commitIfNeeded(true);
  return { processed };
});
