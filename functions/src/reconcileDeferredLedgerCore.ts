import type { Firestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

import { runLedgerAggregate, txDataToPayload } from "./aggregateLedger";
import { getUserTodayYmd, isLedgerDateEffectiveForAggregate } from "./userToday";

/**
 * Applies `accounts` / `monthlyTotals` for this user's deferred future-dated rows
 * whose posting date is now on or before calendar today (profile timezone on `users/{uid}`).
 */
export async function reconcileDeferredLedgerRowsForUser(db: Firestore, uid: string): Promise<number> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const todayYmd = getUserTodayYmd(userSnap.data() as Record<string, unknown> | undefined);

  const snap = await db
    .collection(`users/${uid}/transactions`)
    .where("aggregateDeferred", "==", true)
    .limit(500)
    .get();

  let processed = 0;
  for (const doc of snap.docs) {
    try {
      const data = doc.data();
      const txDate = String(data["transactionDate"] ?? "");
      if (!isLedgerDateEffectiveForAggregate(txDate, todayYmd)) {
        continue;
      }
      const eventId = `reconcile-${doc.id}-${todayYmd}`;
      await runLedgerAggregate(db, uid, eventId, txDataToPayload(data), 1, doc.ref);
      processed += 1;
    } catch (e) {
      logger.error("reconcileDeferredLedgerRowsForUser row failed", doc.ref.path, e);
    }
  }
  return processed;
}
