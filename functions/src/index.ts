import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {
  isAuditOnlyTransactionUpdate,
  isFinancialUnchanged,
  runLedgerAggregate,
  runLedgerAggregateUpdate,
  txDataToPayload,
} from "./aggregateLedger";
import { ingestDailyForexRates } from "./dailyForex";
import { createRecurringFromTransaction } from "./createRecurringFromTransaction";
import { materializeDueUpcoming } from "./materialize";
import { commitOnboarding } from "./onboardingCommit";
import { deleteMyAccount } from "./deleteMyAccount";
import { disconnectMessagingIntegration } from "./disconnectMessagingIntegration";
import { requestMessagingOtp, verifyMessagingOtp } from "./messagingOtp";
import { telegramWebhook } from "./telegramWebhook";
import { reconcileDeferredLedgerForUser } from "./reconcileDeferredLedgerCallable";
import {
  onUserAccountWritten,
  onUserCategoryWritten,
} from "./ledgerCategoryAccountTriggers";
import { touchLedgerSourcesLastChangedAt } from "./userLedgerSync";

initializeApp();

export {
  ingestDailyForexRates,
  materializeDueUpcoming,
  createRecurringFromTransaction,
  commitOnboarding,
  deleteMyAccount,
  disconnectMessagingIntegration,
  requestMessagingOtp,
  verifyMessagingOtp,
  reconcileDeferredLedgerForUser,
  onUserAccountWritten,
  onUserCategoryWritten,
  telegramWebhook,
};

export const onLedgerTransactionWritten = onDocumentWritten(
  {
    document: "users/{uid}/transactions/{txId}",
    region: "us-central1",
  },
  async (event) => {
    const uid = event.params.uid as string;
    const eventId = event.id;
    const before = event.data?.before;
    const after = event.data?.after;

    const db = getFirestore();

    try {
      // Catch-up: meta-only edits (e.g. reload flag) net zero in update-diff path but
      // aggregate never ran for this row (no aggregateApplied). Apply full +1 once.
      if (before?.exists && after?.exists) {
        const bd = before.data() as Record<string, unknown>;
        const ad = after.data() as Record<string, unknown>;
        if (isFinancialUnchanged(bd, ad) && ad["aggregateApplied"] !== true) {
          await runLedgerAggregate(db, uid, eventId, txDataToPayload(ad), 1, after.ref);
          return;
        }
      }

      if (
        isAuditOnlyTransactionUpdate(
          before?.data() as Record<string, unknown> | undefined,
          after?.data() as Record<string, unknown> | undefined
        )
      ) {
        return;
      }

      await touchLedgerSourcesLastChangedAt(db, uid);

      if (!before?.exists && after?.exists) {
        await runLedgerAggregate(db, uid, eventId, txDataToPayload(after.data()!), 1, after.ref);
      } else if (before?.exists && !after?.exists) {
        const bd = before.data() as Record<string, unknown>;
        await runLedgerAggregate(
          db,
          uid,
          eventId,
          txDataToPayload(bd),
          -1,
          undefined,
          { beforeLedgerSnapshot: bd }
        );
      } else if (before?.exists && after?.exists) {
        const bd = before.data() as Record<string, unknown>;
        await runLedgerAggregateUpdate(
          db,
          uid,
          eventId,
          txDataToPayload(bd),
          txDataToPayload(after.data()!),
          after.ref,
          { beforeLedgerSnapshot: bd }
        );
      }
    } catch (e) {
      logger.error("onLedgerTransactionWritten failed", e);
      throw e;
    }
  }
);
