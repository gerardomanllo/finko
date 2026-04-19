import { getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import type { DocumentSnapshot } from "firebase-admin/firestore";

import { touchLedgerSourcesLastChangedAt } from "./userLedgerSync";

const ACCOUNT_AGG_ONLY_KEYS = new Set([
  "balanceMinor",
  "balanceMinorMain",
  "updatedAt",
]);

function accountWriteShouldBumpLedgerSources(
  before: DocumentSnapshot | undefined,
  after: DocumentSnapshot | undefined
): boolean {
  if (after?.exists && !before?.exists) return true;
  if (!after?.exists && before?.exists) return true;
  if (!before?.exists || !after?.exists) return false;
  const b = before.data() as Record<string, unknown>;
  const a = after.data() as Record<string, unknown>;
  const keys = new Set([...Object.keys(b), ...Object.keys(a)]);
  const changed = new Set<string>();
  for (const k of keys) {
    if (JSON.stringify(b[k]) !== JSON.stringify(a[k])) {
      changed.add(k);
    }
  }
  if (changed.size === 0) return false;
  for (const k of changed) {
    if (!ACCOUNT_AGG_ONLY_KEYS.has(k)) return true;
  }
  return false;
}

/** Any category create/update/delete bumps ledger source freshness. */
export const onUserCategoryWritten = onDocumentWritten(
  {
    document: "users/{uid}/categories/{catId}",
    region: "us-central1",
  },
  async (event) => {
    const uid = event.params.uid as string;
    await touchLedgerSourcesLastChangedAt(getFirestore(), uid);
  }
);

/** Account metadata (not balance-only aggregate writes) bumps ledger source freshness. */
export const onUserAccountWritten = onDocumentWritten(
  {
    document: "users/{uid}/accounts/{accountId}",
    region: "us-central1",
  },
  async (event) => {
    const uid = event.params.uid as string;
    const before = event.data?.before;
    const after = event.data?.after;
    if (!accountWriteShouldBumpLedgerSources(before, after)) return;
    await touchLedgerSourcesLastChangedAt(getFirestore(), uid);
  }
);
