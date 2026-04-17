import { randomUUID } from "crypto";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { resolveAsOfYmd } from "./scheduleNext";

type JsonMap = Record<string, unknown>;

function mustString(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${name} is required.`);
  }
  return value.trim();
}

/** Maps Flutter `OnboardingCadence` names to Firestore `recurring.cadence` (see `docs/data-model.md` §9). */
function mapRecurringCadenceFromOnboarding(rule: JsonMap): {
  cadence: string;
  daysOfMonth: number[];
  weekday: number | null;
} {
  const name = mustString(rule.cadence, "recurring.cadence");
  const rawDays = Array.isArray(rule.daysOfMonth) ? (rule.daysOfMonth as number[]) : [];
  const weekday = typeof rule.weekday === "number" ? rule.weekday : null;

  if (name === "biweekly") {
    const sorted = [...rawDays].sort((a, b) => a - b);
    return { cadence: "twiceMonthly", daysOfMonth: sorted, weekday: null };
  }
  if (name === "weekly") {
    return { cadence: "weekly", daysOfMonth: [], weekday };
  }
  if (name === "monthly") {
    return { cadence: "monthly", daysOfMonth: rawDays, weekday: null };
  }
  throw new HttpsError("invalid-argument", "recurring.cadence must be monthly, biweekly, or weekly.");
}

export const commitOnboarding = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const db = getFirestore();
  const payload = (request.data ?? {}) as JsonMap;

  const requestId = mustString(payload.requestId, "requestId");
  const commitRef = db.doc(`users/${uid}/_onboardingCommits/${requestId}`);
  if ((await commitRef.get()).exists) {
    return { committed: true, requestId, deduped: true };
  }

  const profile = (payload.profile ?? {}) as JsonMap;
  const displayName = mustString(profile.displayName, "profile.displayName");
  const timezone = mustString(profile.timezone, "profile.timezone");
  const themePreference = mustString(profile.themePreference, "profile.themePreference");
  const locale = mustString(profile.locale, "profile.locale");
  const mainCurrency =
    typeof profile.mainCurrency === "string" && profile.mainCurrency.trim().length > 0
      ? profile.mainCurrency.trim().toUpperCase()
      : "MXN";

  const accounts = Array.isArray(payload.accounts) ? payload.accounts : [];
  if (accounts.length === 0) {
    throw new HttpsError("invalid-argument", "At least one account is required.");
  }
  const categories = Array.isArray(payload.categories) ? payload.categories : [];

  const recurring = Array.isArray(payload.recurringIncome) ? payload.recurringIncome : [];
  const budgetsMinorByCategory =
    ((payload.budgetsMinorByCategory ?? {}) as JsonMap) || {};

  const categoryKindById = new Map<string, "income" | "expense">();
  for (const raw of categories) {
    const category = raw as JsonMap;
    const categoryId =
      typeof category.id === "string" && category.id.trim().length > 0
        ? category.id.trim()
        : "";
    if (!categoryId) continue;
    const rawKind =
      typeof category.kind === "string" ? category.kind.trim().toLowerCase() : "";
    categoryKindById.set(categoryId, rawKind === "income" ? "income" : "expense");
  }

  const budgetsEmbedded: Record<string, { targetMinorMain: number; kind: "income" | "expense" }> =
    {};
  for (const [categoryId, rawMinor] of Object.entries(budgetsMinorByCategory)) {
    if (typeof rawMinor !== "number" || !Number.isFinite(rawMinor)) continue;
    const targetMinorMain = Math.trunc(rawMinor);
    const kind = categoryKindById.get(categoryId) ?? "expense";
    budgetsEmbedded[categoryId] = { targetMinorMain, kind };
  }

  const messaging = (payload.messaging ?? {}) as JsonMap;

  const monthId = new Date().toISOString().slice(0, 7);
  const today = resolveAsOfYmd({ timezone });
  const userRef = db.doc(`users/${uid}`);
  const monthlyTotalsRef = db.doc(`users/${uid}/monthlyTotals/${monthId}`);

  const batch = db.batch();
  batch.create(commitRef, {
    requestId,
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.set(
    userRef,
    {
      displayName,
      timezone,
      themePreference,
      locale,
      mainCurrency,
      onboardingCompleted: true,
      budgets: budgetsEmbedded,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  for (const raw of accounts) {
    const account = raw as JsonMap;
    const accountId =
      typeof account.id === "string" && account.id.trim().length > 0
        ? account.id.trim()
        : randomUUID();
    const accountRef = db.doc(`users/${uid}/accounts/${accountId}`);
    const accountType = mustString(account.type, "account.type");
    const includeInNetCash =
      typeof account.includeInNetCash === "boolean"
        ? account.includeInNetCash
        : accountType === "checking" || accountType === "creditCard";
    batch.set(
      accountRef,
      {
        name: mustString(account.name, "account.name"),
        type: accountType,
        currency: mustString(account.currency, "account.currency"),
        includeInNetCash,
        colorArgb:
          typeof account.colorArgb === "number" ? account.colorArgb : 0xFF607D8B,
        iconKey:
          typeof account.iconKey === "string" && account.iconKey.trim().length > 0
            ? account.iconKey.trim()
            : "account_balance",
        balanceMinor: 0,
        sortOrder: typeof account.sortOrder === "number" ? account.sortOrder : 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const start = typeof account.startingBalanceMinor === "number" ? account.startingBalanceMinor : 0;
    if (start !== 0) {
      const txRef = db.collection(`users/${uid}/transactions`).doc();
      batch.set(txRef, {
        transactionDate: today,
        loadedAt: FieldValue.serverTimestamp(),
        amountMinor: Math.abs(start),
        direction: start >= 0 ? "in" : "out",
        currency: mustString(account.currency, "account.currency"),
        accountId,
        categoryId: null,
        type: "adjustment",
        memo: "Onboarding starting balance",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  }

  for (const raw of categories) {
    const category = raw as JsonMap;
    const categoryId =
      typeof category.id === "string" && category.id.trim().length > 0
        ? category.id.trim()
        : randomUUID();
    batch.set(
      db.doc(`users/${uid}/categories/${categoryId}`),
      {
        name: mustString(category.name, "category.name"),
        kind: mustString(category.kind, "category.kind"),
        iconKey: mustString(category.iconKey, "category.iconKey"),
        sortOrder: 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  for (const raw of recurring) {
    const rule = raw as JsonMap;
    if (rule.isRecurring !== true) {
      continue;
    }
    const ruleRef = db.collection(`users/${uid}/recurring`).doc();
    const mapped = mapRecurringCadenceFromOnboarding(rule);
    batch.set(ruleRef, {
      name: "Onboarding recurring income",
      kind: "standard",
      amountMinor: typeof rule.amountMinor === "number" ? rule.amountMinor : 0,
      direction: "in",
      currency: "MXN",
      categoryId: mustString(rule.categoryId, "recurring.categoryId"),
      accountId: mustString(rule.accountId, "recurring.accountId"),
      cadence: mapped.cadence,
      daysOfMonth: mapped.daysOfMonth.length > 0 ? mapped.daysOfMonth : [],
      weekday: mapped.weekday,
      active: true,
      nextTransactionDate: today,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    batch.set(db.collection(`users/${uid}/upcomingTransactions`).doc(), {
      transactionDate: today,
      kind: "standard",
      amountMinor: typeof rule.amountMinor === "number" ? rule.amountMinor : 0,
      direction: "in",
      currency: "MXN",
      accountId: mustString(rule.accountId, "recurring.accountId"),
      categoryId: mustString(rule.categoryId, "recurring.categoryId"),
      cadence: mapped.cadence,
      daysOfMonth: mapped.daysOfMonth.length > 0 ? mapped.daysOfMonth : [],
      weekday: mapped.weekday,
      recurringRuleId: ruleRef.id,
      loadedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  batch.set(
    monthlyTotalsRef,
    {
      yearMonth: monthId,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  if (messaging.whatsAppVerified === true && typeof messaging.whatsAppId === "string") {
    batch.set(
      userRef,
      {
        integrations: {
          whatsapp: {
            phoneE164: messaging.whatsAppId,
            verifiedAt: FieldValue.serverTimestamp(),
          },
        },
      },
      { merge: true }
    );
  }
  if (messaging.telegramVerified === true && typeof messaging.telegramId === "string") {
    batch.set(
      userRef,
      {
        integrations: {
          telegram: {
            username: messaging.telegramId,
            verifiedAt: FieldValue.serverTimestamp(),
          },
        },
      },
      { merge: true }
    );
  }

  await batch.commit();
  return { committed: true, requestId, deduped: false };
});
