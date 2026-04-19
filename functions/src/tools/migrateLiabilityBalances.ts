/**
 * One-time migration: negate `balanceMinor` and `balanceMinorMain` on liability
 * accounts (`creditCard`, `loan`, `mortgage`) so stored balances follow
 * **positive = amount owed** after deploying liability-aware `applyAccountDelta`.
 *
 * Run once per Firebase project (dev vs prod separately). Requires Application
 * Default Credentials with Firestore access, e.g.:
 *
 *   cd functions && npm run build && node lib/tools/migrateLiabilityBalances.js
 *
 * Dry-run: set env `DRY_RUN=1` to log actions without writing.
 *
 * **Idempotency:** Running twice inverts twice — only execute once per environment.
 */

import { applicationDefault, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { isLiabilityAccountType } from "../accountKinds";

async function main(): Promise<void> {
  const dryRun = process.env.DRY_RUN === "1" || process.env.DRY_RUN === "true";
  initializeApp({ credential: applicationDefault() });
  const db = getFirestore();
  const usersSnap = await db.collection("users").get();
  let touched = 0;
  for (const user of usersSnap.docs) {
    const accSnap = await db.collection(`users/${user.id}/accounts`).get();
    let batch = db.batch();
    let batchOps = 0;
    for (const doc of accSnap.docs) {
      const data = doc.data();
      const t = typeof data.type === "string" ? data.type : "";
      if (!isLiabilityAccountType(t)) continue;
      const bm = typeof data.balanceMinor === "number" ? data.balanceMinor : 0;
      const bmmRaw = data.balanceMinorMain;
      const bmm = typeof bmmRaw === "number" ? bmmRaw : null;
      const nextMinor = -bm;
      const nextMain = bmm == null ? null : -bmm;
      touched++;
      if (dryRun) {
        // eslint-disable-next-line no-console
        console.log("[dry-run]", doc.ref.path, { balanceMinor: nextMinor, balanceMinorMain: nextMain });
        continue;
      }
      const patch: Record<string, unknown> = {
        balanceMinor: nextMinor,
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (nextMain != null) {
        patch.balanceMinorMain = nextMain;
      }
      batch.update(doc.ref, patch);
      batchOps++;
      if (batchOps >= 450) {
        await batch.commit();
        batch = db.batch();
        batchOps = 0;
      }
    }
    if (!dryRun && batchOps > 0) {
      await batch.commit();
    }
  }
  // eslint-disable-next-line no-console
  console.log(
    dryRun
      ? `Dry-run: ${touched} liability account document(s) would be updated.`
      : `Updated ${touched} liability account document(s).`
  );
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});
