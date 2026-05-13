import type { Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { isLiabilityAccountType } from "./accountKinds";
import {
  computeAmountMain,
  snapshotBalancesIncludedThisRow,
  txDataToPayload,
} from "./aggregateLedger";
import {
  applyAccountDelta,
  dayKeyFromYmd,
  monthKeyFromYmd,
  type BalancePolarity,
} from "./ledgerAggregateMath";
import { sumNetWorthMinorMainFromAccountStates } from "./netWorthFromAccounts";
import { getUserTodayYmd, isLedgerDateEffectiveForAggregate } from "./userToday";

const MAX_TX_FOR_REPLAY = 25_000;

function defaultMonthly(yearMonth: string) {
  return {
    yearMonth,
    incomeMinorMain: 0,
    expenseMinorMain: 0,
    byCategoryMinorMain: {} as Record<string, number>,
    days: {} as Record<string, Record<string, unknown>>,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

type BalanceRow = {
  balanceMinor: number;
  balanceMinorMain: number;
  balancePolarity: BalancePolarity;
};

/**
 * Recomputes `monthlyTotals/{yyyy-mm}.days.{dd}.netWorthEodMinorMain` for every calendar day
 * in the month that has at least one effective ledger row, by genesis-replay of all effective
 * transactions (ordered), then merges into the existing month doc.
 */
export async function rebuildNetWorthSeriesForMonth(
  db: Firestore,
  uid: string,
  ym: string,
  userData: Record<string, unknown> | undefined
): Promise<void> {
  const mainCurrency = (userData?.mainCurrency as string) ?? "MXN";
  const todayYmd = getUserTodayYmd(userData);

  const accountsSnap = await db.collection(`users/${uid}/accounts`).get();
  const balances = new Map<string, BalanceRow>();
  for (const doc of accountsSnap.docs) {
    const data = doc.data();
    const rawType = typeof data.type === "string" ? data.type : "";
    const balancePolarity: BalancePolarity = isLiabilityAccountType(rawType)
      ? "liability"
      : "asset";
    balances.set(doc.id, {
      balanceMinor: 0,
      balanceMinorMain: 0,
      balancePolarity,
    });
  }

  const txCol = db.collection(`users/${uid}/transactions`);
  const txSnap = await txCol.orderBy("transactionDate").limit(MAX_TX_FOR_REPLAY).get();
  if (txSnap.size >= MAX_TX_FOR_REPLAY) {
    logger.warn("rebuildNetWorthSeriesForMonth: transaction query at cap", { uid, ym });
  }

  const rows = txSnap.docs
    .map((d) => ({ id: d.id, data: d.data() as Record<string, unknown> }))
    .filter((row) => snapshotBalancesIncludedThisRow(row.data))
    .filter((row) =>
      isLedgerDateEffectiveForAggregate(String(row.data.transactionDate ?? ""), todayYmd)
    );

  rows.sort((a, b) => {
    const da = String(a.data.transactionDate ?? "");
    const db0 = String(b.data.transactionDate ?? "");
    if (da !== db0) return da.localeCompare(db0);
    return a.id.localeCompare(b.id);
  });

  const nwByDay: Record<string, number> = {};

  for (const row of rows) {
    const raw = row.data;
    const payload = txDataToPayload(raw);
    let amountMain: number;
    const storedMain = raw.amountMinorMain;
    if (typeof storedMain === "number" && Number.isFinite(storedMain)) {
      amountMain = Math.trunc(storedMain);
    } else {
      amountMain = await computeAmountMain(db, mainCurrency, payload);
    }

    let accState = balances.get(payload.accountId);
    if (!accState) {
      const accDoc = await db.doc(`users/${uid}/accounts/${payload.accountId}`).get();
      const rawType =
        accDoc.exists && typeof accDoc.data()?.type === "string"
          ? (accDoc.data()!.type as string)
          : "";
      const pol: BalancePolarity = isLiabilityAccountType(rawType) ? "liability" : "asset";
      accState = { balanceMinor: 0, balanceMinorMain: 0, balancePolarity: pol };
      balances.set(payload.accountId, accState);
    }

    applyAccountDelta(accState, payload, 1, amountMain, accState.balancePolarity);

    if (monthKeyFromYmd(payload.transactionDate) !== ym) continue;

    const dd = dayKeyFromYmd(payload.transactionDate);
    nwByDay[dd] = sumNetWorthMinorMainFromAccountStates(balances.values());
  }

  const monthRef = db.doc(`users/${uid}/monthlyTotals/${ym}`);
  const existing = await monthRef.get();
  const base = existing.exists
    ? ({ ...(existing.data() as Record<string, unknown>) } as Record<string, unknown>)
    : defaultMonthly(ym);

  const days = {
    ...((base.days ?? {}) as Record<string, Record<string, unknown>>),
  };
  for (const [dd, nw] of Object.entries(nwByDay)) {
    days[dd] = { ...(days[dd] ?? {}), netWorthEodMinorMain: nw };
  }
  base.days = days;
  base.updatedAt = FieldValue.serverTimestamp();

  await monthRef.set(base, { merge: true });
}
