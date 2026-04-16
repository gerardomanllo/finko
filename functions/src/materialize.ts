import { randomUUID } from "crypto";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

function addOneMonthYmd(ymd: string): string {
  const [y, m, d] = ymd.split("-").map((x) => Number(x));
  const dt = new Date(Date.UTC(y, m - 1 + 1, d));
  return dt.toISOString().slice(0, 10);
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
  const asOfDate =
    (request.data?.asOfDate as string | undefined) ??
    new Date().toISOString().slice(0, 10);

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

    if (kind === "standard") {
      const txRef = db.collection(`users/${uid}/transactions`).doc();
      batch.set(txRef, {
        transactionDate: u.transactionDate,
        loadedAt: FieldValue.serverTimestamp(),
        amountMinor: u.amountMinor,
        direction: u.direction,
        currency: u.currency,
        accountId: u.accountId,
        categoryId: u.categoryId ?? null,
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
      const gid = u.transferGroupId ?? randomUUID();
      const outRef = db.collection(`users/${uid}/transactions`).doc();
      const inRef = db.collection(`users/${uid}/transactions`).doc();
      batch.set(outRef, {
        transactionDate: u.transactionDate,
        loadedAt: FieldValue.serverTimestamp(),
        amountMinor: u.amountMinor,
        direction: "out",
        currency: u.currency,
        accountId: fromId,
        categoryId: null,
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
        categoryId: null,
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

    const cadence = u.cadence as string | undefined;
    if (cadence === "monthly" || cadence === "twiceMonthly" || cadence === "biweekly") {
      const next = addOneMonthYmd(u.transactionDate as string);
      batch.update(doc.ref, {
        transactionDate: next,
        updatedAt: FieldValue.serverTimestamp(),
      });
      ops++;
    } else {
      batch.delete(doc.ref);
      ops++;
    }

    processed++;
    await commitIfNeeded();
  }

  await commitIfNeeded(true);
  return { processed };
});
