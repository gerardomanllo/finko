# Data contract (app ↔ Firestore)

This document defines **how Flutter code accesses data** so **widgets stay in sync** with Firestore **as fast as the network allows**, with **no polling** for core reads. It complements [`data-model.md`](data-model.md) and [`backend-strategy.md`](backend-strategy.md).

---

## 1. Principles

| Principle | Requirement |
|-------------|-------------|
| **Real-time** | Use Firestore **`snapshots()`** streams for all **authoritative** UI state that must reflect remote changes (including other devices). |
| **Single source of truth** | **`transactions`** + denormalized docs (`accounts`, `monthlyTotals`, …) updated by **Cloud Functions** on write—never rely on stale client-only math for dashboard numbers. |
| **No scheduled *aggregate* repair** | **No** cron-driven recomputation of transaction totals for MVP; Functions run **on transaction write** to keep aggregates current. **Exception:** **daily forex ingestion** only (see [`data-model.md` §10](data-model.md)). |
| **Reactive UI** | Widgets **`ref.watch`** stream-based providers so they **rebuild automatically** when new snapshot data arrives. |
| **Explicit async** | Loading/error/empty states use a **consistent** pattern (`AsyncValue` or sealed union). |

---

## 2. Layering (Flutter)

```
Firestore
    ↑ snapshots() / one-shot get()
Repository (per domain: transactions, dashboard, budgets, …)
    ↑ exposes Stream<T> / Future<T>
Riverpod providers (StreamProvider, FutureProvider, Notifier if local-only)
    ↑ ref.watch / ref.listen
Widgets (ConsumerWidget, HookConsumerWidget, …)
```

- **Repositories** encapsulate Firestore paths, query shapes, and mapping to **immutable** Dart models (`freezed` / plain classes).
- **Providers** are **thin**: map `uid` + parameters → repository stream. **No** duplicated business logic in widgets.
- **Widgets** never call `FirebaseFirestore.instance` directly (except in repository implementations).

---

## 3. Real-time subscription contract

### 3.1 Default: stream providers

For any document or query that should **live-update**, expose:

```dart
// Illustrative — names follow project conventions
final monthlyTotalsProvider = StreamProvider.family<MonthlyTotals?, String>((ref, yyyyMm) async* {
  final uid = ref.watch(authUidProvider);
  if (uid == null) { yield null; return; }
  yield* ref.watch(firestoreRepositoryProvider).watchMonthlyTotals(uid, yyyyMm);
});
```

Rules:

- **`StreamProvider` / `StreamNotifier`** for **snapshots**.
- Use **`family`** when the UI parameterizes by month, account id, etc.
- **`authUidProvider`** (or equivalent) gates all streams: if signed out, emit **null** or closed state—widgets show empty/login.

### 3.2 One-shot reads

Use **`FutureProvider`** / **`get()`** only for cold data, explicit exports, or **materialization** triggers that return after work completes (see §11).

### 3.3 Multiple listeners

Prefer **one provider per logical subscription**; **`ref.watch`** the same provider from many widgets.

---

## 4. Widget responsibilities

| Do | Don’t |
|----|--------|
| **`ref.watch(streamProvider)`** so the subtree rebuilds on every emission | Cache “today’s totals” in `StateProvider` and forget to invalidate |
| Show **`AsyncValue`** with loading/error UI | Swallow errors silently |
| Use **`ref.listen`** for side effects (snackbars, navigation on auth change) | Call `get()` in `build()` in a loop |
| Keep widgets **pure** on data: map model → UI | Recompute month totals in the widget from raw transactions |

When a **transaction is created/updated**:

1. Client writes **`transactions/{txId}`** (and paired leg for transfers).
2. **Cloud Functions** update **`monthlyTotals`**, **`accounts`**, etc. (using **FX** from `forexRates` for main-currency fields).
3. Listeners **emit** → providers update → **widgets rebuild**.

---

## 5. Screen → provider mapping (illustrative)

| Screen / area | Primary subscriptions (examples) |
|-----------------|-----------------------------------|
| **Dashboard** | `accountsStreamProvider`; `userProfileStreamProvider`; **`currentMonthTotalsStreamProvider`** → `monthlyTotals/{yyyy-MM}` (expense totals + embedded `budgets` + `days` for net-worth sparkline); **`netWorthSparklineSeriesProvider`** (30-day series, may read two month docs); **`recentTransactionsStreamProvider`**; **`upcomingTransactionsStreamProvider`** (UI filters to **strictly future** dates); pull-to-refresh invalidates streams + **`materializeDueUpcoming`**. Optional `forexRates` if UI shows rate context. |
| **Spending** | `monthlyTotals` for months in range; derive week/quarter/year in provider. |
| **Transactions** | `transactions` query by `transactionDate` / `loadedAt` as designed; paginate. |
| **Budgets** | **`monthlyTotals/{yyyy-mm}`** only (budgets embedded in doc). |
| **Categories / accounts** | Collection snapshots. |
| **Recurring / upcoming** | **`upcomingTransactionsStreamProvider`** (canonical schedule rows); **`recurringRulesStreamProvider`** + **`categoriesStreamProvider`** for labels/icons; **`todayYyyyMmDdProvider`** uses profile timezone when set. Pull-to-refresh: **`materializeDueUpcoming`** + invalidate streams. |

---

## 6. Error, loading, and consistency

- **`AsyncValue.when`** in UI: loading, error (retry), data (empty vs populated).
- **Write lag:** Expect **one or two** snapshot updates after a save while Functions run; listen to **aggregate** docs for stable numbers.
- **Offline:** Firestore persistence optional—surface offline indicator if product requires.

---

## 7. Testing against the contract

- **Unit tests:** Fake repositories emitting **streams**.
- **Widget tests:** `ProviderScope` **overrides** (`finko-riverpod-testing.mdc`).

---

## 8. Non-goals (MVP)

- **No** `Timer.periodic` refresh for core money data.
- **No** nightly jobs that **re-sum** transactions from scratch—**forex daily job** is allowed ([`data-model.md` §10](data-model.md)).

---

## 9. Open questions (product / impl)

1. **Firestore persistence** on mobile/web for offline-first UX?
2. **Transaction list pagination:** cursor + stream strategy vs paged futures.
3. **Optimistic UI:** spinner until aggregates match vs optimistic row-only feedback.

---

## 10. Forex rates & aggregates

- Clients **subscribe** to **`monthlyTotals`** / **`accounts`** as usual; when **`forexRates/{date}`** updates (after the daily job), **Functions** may **re-touch** aggregates for open months if product requires **restated** main-currency totals—or rates apply **only to new writes** (**policy**: implement explicitly). **Conversion** when a date has no rate doc follows [`data-model.md` §10](data-model.md) (**walk backward** to previous stored day).
- UI does not poll Frankfurter directly for every screen; **read** cached `forexRates` from Firestore if you display rates.

---

## 11. UpcomingTransactions & daily materialization

**Goal:** [`data-model.md` §8](data-model.md) — due rows become **real** `transactions`, and upcoming rows **advance** to their next effective date.

**Recommended implementation**

1. **Callable Cloud Function** `materializeDueUpcoming`, idempotent:
   - Input: `uid`, optional `asOfDate` (**yyyy-MM-dd**), optional `timezone` (IANA). **`resolveAsOfYmd`** in **`functions/src/scheduleNext.ts`**: explicit `asOfDate` wins; else **today’s calendar date in `timezone`** when set; else server-local calendar day.
   - Query `upcomingTransactions` where `transactionDate` **≤** `asOfDate`.
   - For each doc: create **`transactions`** (and any transfer pair), **`sourceUpcomingId`** on new txs, then **advance** `transactionDate` using **`computeNextTransactionDate`** (cadence + `daysOfMonth` + `weekday`), **update** `recurring/{id}.nextTransactionDate` when **`recurringRuleId`** is set, or **delete** upcoming (and linked rule when applicable) if no next date.
2. **When to call:** On **app start** and optionally **resume** (once per calendar day per device—use `SharedPreferences` / local flag `lastMaterializeDate` to avoid redundant calls, or rely on idempotent CF).
3. **After return:** Existing **`snapshots()`** on `transactions` and `monthlyTotals` **emit**—widgets already watching **update automatically**.

**Alternative (not preferred):** Client-side batch writes with strict security rules—harder to keep **atomic** and **safe**.

**Widgets:** After splash / login, **`ref.listen`** or **`WidgetsBinding.instance.addPostFrameCallback`** triggers the callable **once**, then dashboard streams show fresh data—**no** manual “refresh” button required for this path.

---

## 12. Ledger aggregation (Cloud Functions)

**Source of truth:** `accounts` balances and `monthlyTotals` (including embedded **`days.{dd}`** maps) are updated by **`onLedgerTransactionWritten`** in **`functions/`**, not by recomputing the full ledger in the Flutter client. See [`data-model.md` §4.1–4.1a](data-model.md) for idempotency, **`aggregateApplied`**, and **catch-up** when a transaction row exists but aggregates were never applied.

**Client expectations**

- After writing a **transaction**, watch **`accounts`** and **`monthlyTotals`** streams; totals update after Functions finish (usually one or two snapshot ticks).
- **`monthlyTotals/{yyyy-mm}`** is a **single document**; **`days`** is a **map** on that document (not a subcollection).
- **`aggregateApplied`** on a transaction is **server-owned**; the app may read it for diagnostics but **must not** set it to `true` in production (enforce in rules per [`data-model.md` §11](data-model.md)).
- Optional **`reload`** / **`aggregateReload`** fields are only for **re-firing** the aggregate when money fields are unchanged (e.g. ops / debugging). Product UI should not depend on them unless we add a first-class “repair” flow.

**Pull-to-refresh / materialization** (app): dashboard refresh and **`materializeDueUpcoming`** complement aggregates but do not replace the transaction trigger above.

---

## 13. Revision log

| Date | Change |
|------|--------|
| 2026-04-14 | Initial contract: streams, Riverpod, widget rules, no batch jobs, screen→subscription map. |
| 2026-04-14 | Scheduled **forex** allowed; budgets in `monthlyTotals`; `upcomingTransactions` + callable materialization; multi-currency. |
| 2026-04-16 | **§12** Ledger aggregation (Functions vs client, `aggregateApplied`, `days` map, optional reload fields). |
| 2026-04-16 | **§5** Dashboard row: named providers + net-worth sparkline source, refresh/materialize. |
| 2026-04-16 | **§5** Recurring row: named providers; **§11** callable `asOfDate` / `timezone` resolution + next-date + `recurring` sync. |
