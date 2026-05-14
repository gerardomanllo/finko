import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/firebase_auth_providers.dart';
import '../../datetime/user_calendar_date.dart';
import '../models/models.dart';
import '../repositories/firestore_data_repository.dart';

final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// Calendar month key `yyyy-MM` for the device-local "current month".
final currentYearMonthProvider = Provider<String>((ref) {
  return _yearMonthKey(ref.watch(nowProvider));
});

/// `yyyy-MM` from profile-aware [`todayYyyyMmDdProvider`] — use on **dashboard** so
/// month docs align with business "today".
final dashboardYearMonthProvider = Provider<String>(
  (ref) => ref.watch(todayYyyyMmDdProvider).substring(0, 7),
);

final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) async* {
  final uid = ref.watch(authUidProvider);
  if (uid == null) {
    yield null;
    return;
  }
  yield* ref.watch(firestoreDataRepositoryProvider).watchUserProfile(uid);
});

/// Business "today" as `yyyy-MM-dd`: profile [UserProfile.timezone] when set, else device-local.
final todayYyyyMmDdProvider = Provider<String>((ref) {
  final now = ref.watch(nowProvider);
  final tzName = ref.watch(userProfileStreamProvider).valueOrNull?.timezone;
  return userCalendarDateYyyyMmDd(utcNow: now.toUtc(), ianaTimezone: tzName);
});

final accountsStreamProvider = StreamProvider<List<FinkoAccount>>((ref) async* {
  final uid = ref.watch(authUidProvider);
  if (uid == null) {
    yield <FinkoAccount>[];
    return;
  }
  yield* ref.watch(firestoreDataRepositoryProvider).watchAccounts(uid);
});

final currentMonthTotalsStreamProvider = StreamProvider<MonthlyTotals?>((
  ref,
) async* {
  final uid = ref.watch(authUidProvider);
  if (uid == null) {
    yield null;
    return;
  }
  final ym = ref.watch(currentYearMonthProvider);
  yield* ref.watch(firestoreDataRepositoryProvider).watchMonthlyTotals(uid, ym);
});

/// Monthly totals for an arbitrary `yyyy-MM` (e.g. budgets month pager).
final monthlyTotalsForMonthStreamProvider =
    StreamProvider.family<MonthlyTotals?, String>((ref, yyyyMm) async* {
      final uid = ref.watch(authUidProvider);
      if (uid == null) {
        yield null;
        return;
      }
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchMonthlyTotals(uid, yyyyMm);
    });

final recentTransactionsStreamProvider =
    StreamProvider<List<LedgerTransaction>>((ref) async* {
      final uid = ref.watch(authUidProvider);
      if (uid == null) {
        yield <LedgerTransaction>[];
        return;
      }
      final today = ref.watch(todayYyyyMmDdProvider);
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchRecentTransactions(uid, limit: 80)
          .map(
            (list) => list
                .where((t) => t.transactionDate.compareTo(today) <= 0)
                .take(5)
                .toList(),
          );
    });

final upcomingTransactionsStreamProvider =
    StreamProvider<List<UpcomingTransaction>>((ref) async* {
      final uid = ref.watch(authUidProvider);
      if (uid == null) {
        yield <UpcomingTransaction>[];
        return;
      }
      final from = ref.watch(todayYyyyMmDdProvider);
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchUpcomingFromDate(uid, from, limit: 50);
    });

/// Future-dated **`transactions/`** rows (editor-created), strictly **after** profile today.
///
/// Dashboard próximos strip — see [mergeUpcomingForUi] with `includeDueToday: false`.
final futureDatedLedgerTransactionsStreamProvider =
    StreamProvider<List<LedgerTransaction>>((ref) async* {
      final uid = ref.watch(authUidProvider);
      if (uid == null) {
        yield <LedgerTransaction>[];
        return;
      }
      final today = ref.watch(todayYyyyMmDdProvider);
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchLedgerTransactionsAfterDate(uid, today, limit: 40);
    });

/// Ledger rows with `transactionDate` **on or after** profile today (same limit).
///
/// Used for [recurringMergedUpcomingProvider] so today’s future-dated ledger previews
/// are not dropped by the Firestore `isGreaterThan` query.
final ledgerFromTodayForUpcomingMergeStreamProvider =
    StreamProvider<List<LedgerTransaction>>((ref) async* {
      final uid = ref.watch(authUidProvider);
      if (uid == null) {
        yield <LedgerTransaction>[];
        return;
      }
      final today = ref.watch(todayYyyyMmDdProvider);
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchLedgerTransactionsAfterDate(
            uid,
            today,
            limit: 40,
            inclusiveFrom: true,
          );
    });

/// Upcoming strip for dashboard: scheduled rows **after** today plus recurring
/// rules whose [RecurringRule.nextTransactionDate] is not already represented.
final dashboardUpcomingStripProvider =
    Provider<AsyncValue<List<UpcomingTransaction>>>((ref) {
      final today = ref.watch(todayYyyyMmDdProvider);
      return ref
          .watch(upcomingTransactionsStreamProvider)
          .when(
            data: (upcomingList) => ref
                .watch(recurringRulesStreamProvider)
                .when(
                  data: (rules) => ref
                      .watch(futureDatedLedgerTransactionsStreamProvider)
                      .when(
                        data: (ledgerFuture) => AsyncValue.data(
                          mergeUpcomingForUi(
                            upcomingList,
                            rules,
                            today,
                            ledgerFuture: ledgerFuture,
                            includeDueToday: false,
                          ),
                        ),
                        loading: () => const AsyncValue.loading(),
                        error: AsyncValue.error,
                      ),
                  loading: () => const AsyncValue.loading(),
                  error: AsyncValue.error,
                ),
            loading: () => const AsyncValue.loading(),
            error: AsyncValue.error,
          );
    });

/// Recurring screen: same merge as [dashboardUpcomingStripProvider] but **includes
/// rows due today** (matches calendar / Due soon `days >= 0`), plus future-dated
/// ledger previews — see KB-008 / `docs/data-contract.md`.
final recurringMergedUpcomingProvider =
    Provider<AsyncValue<List<UpcomingTransaction>>>((ref) {
      final today = ref.watch(todayYyyyMmDdProvider);
      return ref
          .watch(upcomingTransactionsStreamProvider)
          .when(
            data: (upcomingList) => ref
                .watch(recurringRulesStreamProvider)
                .when(
                  data: (rules) => ref
                      .watch(ledgerFromTodayForUpcomingMergeStreamProvider)
                      .when(
                        data: (ledgerFuture) => AsyncValue.data(
                          mergeUpcomingForUi(
                            upcomingList,
                            rules,
                            today,
                            ledgerFuture: ledgerFuture,
                            includeDueToday: true,
                          ),
                        ),
                        loading: () => const AsyncValue.loading(),
                        error: AsyncValue.error,
                      ),
                  loading: () => const AsyncValue.loading(),
                  error: AsyncValue.error,
                ),
            loading: () => const AsyncValue.loading(),
            error: AsyncValue.error,
          );
    });

/// Merges Firestore `upcomingTransactions`, synthetic previews from [RecurringRule]s,
/// and future-dated ledger rows for UI.
///
/// [includeDueToday] — **`false`**: dashboard strip (strictly **after** today for
/// schedule rows; ledger previews only **after** today). **`true`**: Recurring
/// screen (today and future for schedule rows **and** ledger previews).
List<UpcomingTransaction> mergeUpcomingForUi(
  List<UpcomingTransaction> upcoming,
  List<RecurringRule> rules,
  String todayYyyyMmDd, {
  List<LedgerTransaction> ledgerFuture = const [],
  required bool includeDueToday,
}) {
  final out = upcoming
      .where(
        (u) => includeDueToday
            ? u.transactionDate.compareTo(todayYyyyMmDd) >= 0
            : u.transactionDate.compareTo(todayYyyyMmDd) > 0,
      )
      .toList();

  final covered = <String>{};
  for (final u in out) {
    if (u.recurringRuleId != null) {
      covered.add('${u.recurringRuleId}|${u.transactionDate}');
    }
  }

  final now = DateTime.now();
  for (final rule in rules) {
    if (!rule.active) continue;
    final ruleOk = includeDueToday
        ? rule.nextTransactionDate.compareTo(todayYyyyMmDd) >= 0
        : rule.nextTransactionDate.compareTo(todayYyyyMmDd) > 0;
    if (!ruleOk) continue;
    final key = '${rule.id}|${rule.nextTransactionDate}';
    if (covered.contains(key)) continue;
    out.add(UpcomingTransaction.fromRecurringRulePreview(rule, now: now));
    covered.add(key);
  }

  for (final t in ledgerFuture) {
    final skipLedgerRow = includeDueToday
        ? t.transactionDate.compareTo(todayYyyyMmDd) < 0
        : t.transactionDate.compareTo(todayYyyyMmDd) <= 0;
    if (skipLedgerRow) continue;
    if (t.type == LedgerTransactionKind.transferLeg &&
        t.direction == MoneyDirection.in_) {
      continue;
    }
    out.add(UpcomingTransaction.fromLedgerPreview(t, now: now));
  }

  out.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
  return out;
}

/// Ledger rows with `transactionDate` in [**start**, **end**] inclusive ([`docs/data-contract.md`]).
final transactionsForDateRangeStreamProvider =
    StreamProvider.family<
      List<LedgerTransaction>,
      ({String start, String end})
    >((ref, range) async* {
      final uid = ref.watch(authUidProvider);
      if (uid == null) {
        yield <LedgerTransaction>[];
        return;
      }
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchTransactionsForDateRange(
            uid,
            startYyyyMmDd: range.start,
            endYyyyMmDd: range.end,
          );
    });

final categoriesStreamProvider = StreamProvider<List<FinkoCategory>>((
  ref,
) async* {
  final uid = ref.watch(authUidProvider);
  if (uid == null) {
    yield <FinkoCategory>[];
    return;
  }
  yield* ref.watch(firestoreDataRepositoryProvider).watchCategories(uid);
});

final recurringRulesStreamProvider = StreamProvider<List<RecurringRule>>((
  ref,
) async* {
  final uid = ref.watch(authUidProvider);
  if (uid == null) {
    yield <RecurringRule>[];
    return;
  }
  yield* ref.watch(firestoreDataRepositoryProvider).watchRecurringRules(uid);
});

/// Latest known global rate doc for [dateKey] `yyyy-mm-dd` (often today).
final forexRatesForDateStreamProvider =
    StreamProvider.family<ForexRatesDoc?, String>((ref, dateKey) async* {
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchForexRates(dateKey);
    });

/// Last 30 daily net-worth points from `monthlyTotals.days.*.netWorthEodMinorMain`.
///
/// Each value is the **signed sum of all account balances in main currency**
/// (`balanceMinorMain`) written by Cloud Functions after ledger aggregates
/// (see `sumNetWorthMinorMainFromAccountStates` / `rebuildNetWorthSeriesForMonth` in `functions/`).
///
/// Missing days use forward-fill inside the 30-day window; if no prior value
/// exists in-window yet, the point is `0`.
///
/// Window ends on profile-aware **today** ([`todayYyyyMmDdProvider`]) so points
/// are not tied to device-local midnight when the user has a timezone set.
///
/// Loads every `monthlyTotals/{yyyy-mm}` that intersects the window (one to
/// three months — e.g. Jan 31 through Mar 1 spans three).
final netWorthSparklineSeriesProvider = Provider<List<double>>((ref) {
  final endDate = _dateOnlyFromYyyyMmDd(ref.watch(todayYyyyMmDdProvider));
  final startDate = endDate.subtract(const Duration(days: 29));

  final monthKeys = <String>{};
  for (var i = 0; i < 30; i++) {
    monthKeys.add(_yearMonthKey(startDate.add(Duration(days: i))));
  }

  final monthData = <String, MonthlyTotals?>{};
  for (final mk in monthKeys) {
    monthData[mk] = ref
        .watch(monthlyTotalsForMonthStreamProvider(mk))
        .valueOrNull;
  }

  var hasPrevious = false;
  var previousValue = 0;
  final series = <double>[];

  for (var i = 0; i < 30; i++) {
    final day = startDate.add(Duration(days: i));
    final month = monthData[_yearMonthKey(day)];
    final key = day.day.toString().padLeft(2, '0');
    final point = month?.days[key]?.netWorthEodMinorMain;
    if (point != null) {
      series.add(point.toDouble());
      previousValue = point;
      hasPrevious = true;
      continue;
    }
    series.add(hasPrevious ? previousValue.toDouble() : 0);
  }
  return series;
});

/// One point per calendar day in [dashboardYearMonthProvider]: **cumulative**
/// expense through that day (running total), i.e. sum of
/// **`days.{01}.expenseMinorMain` … `days.{dd}.expenseMinorMain`** in main currency.
///
/// Length is always **days in that month**; a missing day key counts as **0** for
/// that day (the total carries forward unchanged until a later day adds spend).
final dashboardMonthDailyExpenseSeriesProvider = Provider<List<double>>((ref) {
  final ym = ref.watch(dashboardYearMonthProvider);
  final parts = ym.split('-');
  if (parts.length != 2) {
    return <double>[];
  }
  final y = int.tryParse(parts[0]) ?? 2000;
  final m = int.tryParse(parts[1]) ?? 1;
  final daysInMonth = DateTime(y, m + 1, 0).day;

  final totals = ref.watch(monthlyTotalsForMonthStreamProvider(ym)).valueOrNull;

  var running = 0;
  final series = <double>[];
  for (var d = 1; d <= daysInMonth; d++) {
    final key = d.toString().padLeft(2, '0');
    final raw = totals?.days[key]?.expenseMinorMain;
    running += raw ?? 0;
    series.add(running.toDouble());
  }
  return series;
});

DateTime _dateOnlyFromYyyyMmDd(String yyyyMmDd) {
  final parts = yyyyMmDd.split('-');
  if (parts.length != 3) {
    return _dateOnly(DateTime.now());
  }
  return DateTime(
    int.tryParse(parts[0]) ?? 0,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[2]) ?? 1,
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _yearMonthKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}';
