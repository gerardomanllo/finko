import { FieldValue, type Firestore } from "firebase-admin/firestore";

/** Client-readable; server-only writes (rules + Admin SDK). */
export async function touchLedgerSourcesLastChangedAt(
  db: Firestore,
  uid: string
): Promise<void> {
  await db.doc(`users/${uid}`).set(
    { ledgerSourcesLastChangedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
}

export async function touchAggregateLastCompletedAt(
  db: Firestore,
  uid: string
): Promise<void> {
  await db.doc(`users/${uid}`).set(
    { aggregateLastCompletedAt: FieldValue.serverTimestamp() },
    { merge: true }
  );
}
