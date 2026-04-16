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

/// Future-dated **`transactions/`** rows (editor-created), strictly after profile today.
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
                          mergeDashboardUpcoming(
                            upcomingList,
                            rules,
                            today,
                            ledgerFuture: ledgerFuture,
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

List<UpcomingTransaction> mergeDashboardUpcoming(
  List<UpcomingTransaction> upcoming,
  List<RecurringRule> rules,
  String todayYyyyMmDd, {
  List<LedgerTransaction> ledgerFuture = const [],
}) {
  final out = upcoming
      .where((u) => u.transactionDate.compareTo(todayYyyyMmDd) > 0)
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
    if (rule.nextTransactionDate.compareTo(todayYyyyMmDd) <= 0) continue;
    final key = '${rule.id}|${rule.nextTransactionDate}';
    if (covered.contains(key)) continue;
    out.add(UpcomingTransaction.fromRecurringRulePreview(rule, now: now));
    covered.add(key);
  }

  for (final t in ledgerFuture) {
    if (t.transactionDate.compareTo(todayYyyyMmDd) <= 0) continue;
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
/// Missing days use forward-fill inside the 30-day window; if no prior value
/// exists in-window yet, the point is `0`.
///
/// Window ends on profile-aware **today** ([`todayYyyyMmDdProvider`]) so points
/// are not tied to device-local midnight when the user has a timezone set.
final netWorthSparklineSeriesProvider = Provider<List<double>>((ref) {
  final endDate = _dateOnlyFromYyyyMmDd(ref.watch(todayYyyyMmDdProvider));
  final startDate = endDate.subtract(const Duration(days: 29));
  final endMonthKey = _yearMonthKey(endDate);
  final startMonthKey = _yearMonthKey(startDate);

  final endMonth = ref.watch(monthlyTotalsForMonthStreamProvider(endMonthKey));
  final startMonth = startMonthKey == endMonthKey
      ? endMonth
      : ref.watch(monthlyTotalsForMonthStreamProvider(startMonthKey));

  final endMonthData = endMonth.valueOrNull;
  final startMonthData = startMonth.valueOrNull;
  var hasPrevious = false;
  var previousValue = 0;
  final series = <double>[];

  for (var i = 0; i < 30; i++) {
    final day = startDate.add(Duration(days: i));
    final month = _yearMonthKey(day) == endMonthKey
        ? endMonthData
        : startMonthData;
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
