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
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchRecentTransactions(uid, limit: 20);
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
final netWorthSparklineSeriesProvider = Provider<List<double>>((ref) {
  final endDate = _dateOnly(ref.watch(nowProvider));
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

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _yearMonthKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}';
