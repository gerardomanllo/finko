import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {
  isAuditOnlyTransactionUpdate,
  runLedgerAggregate,
  runLedgerAggregateUpdate,
  txDataToPayload,
} from "./aggregateLedger";
import { ingestDailyForexRates } from "./dailyForex";
import { materializeDueUpcoming } from "./materialize";
import { commitOnboarding } from "./onboardingCommit";
import { requestMessagingOtp, verifyMessagingOtp } from "./messagingOtp";

initializeApp();

export {
  ingestDailyForexRates,
  materializeDueUpcoming,
  commitOnboarding,
  requestMessagingOtp,
  verifyMessagingOtp,
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

    if (
      isAuditOnlyTransactionUpdate(
        before?.data() as Record<string, unknown> | undefined,
        after?.data() as Record<string, unknown> | undefined
      )
    ) {
      return;
    }

    const db = getFirestore();

    try {
      if (!before?.exists && after?.exists) {
        await runLedgerAggregate(db, uid, eventId, txDataToPayload(after.data()!), 1);
      } else if (before?.exists && !after?.exists) {
        await runLedgerAggregate(db, uid, eventId, txDataToPayload(before.data()!), -1);
      } else if (before?.exists && after?.exists) {
        await runLedgerAggregateUpdate(
          db,
          uid,
          eventId,
          txDataToPayload(before.data()!),
          txDataToPayload(after.data()!)
        );
      }
    } catch (e) {
      logger.error("onLedgerTransactionWritten failed", e);
      throw e;
    }
  }
);
