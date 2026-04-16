import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { reconcileDeferredLedgerRowsForUser } from "./reconcileDeferredLedgerCore";

/**
 * Client-invoked (app open / pull-to-refresh): applies deferred ledger aggregates for the
 * signed-in user. Not scheduled — see `DeferredLedgerReconcileService` in Flutter.
 */
export const reconcileDeferredLedgerForUser = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.data?.uid as string | undefined;
  if (!uid || uid !== request.auth.uid) {
    throw new HttpsError("permission-denied", "UID mismatch.");
  }
  const db = getFirestore();
  const processed = await reconcileDeferredLedgerRowsForUser(db, uid);
  return { processed };
});
