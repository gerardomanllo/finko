import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/firebase_auth_providers.dart';
import '../models/models.dart';
import '../repositories/firestore_data_repository.dart';

/// Calendar month key `yyyy-MM` for the device-local "current month".
final currentYearMonthProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}';
});

/// Device-local business date `yyyy-MM-dd` (fallback until profile timezone drives materialization).
final todayYyyyMmDdProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
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

/// Latest known global rate doc for [dateKey] `yyyy-mm-dd` (often today).
final forexRatesForDateStreamProvider =
    StreamProvider.family<ForexRatesDoc?, String>((ref, dateKey) async* {
      yield* ref
          .watch(firestoreDataRepositoryProvider)
          .watchForexRates(dateKey);
    });
