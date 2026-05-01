import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/firebase_auth_providers.dart';
import '../data/providers/finko_stream_providers.dart';
import '../data/repositories/firestore_data_repository.dart';
import '../upcoming/deferred_ledger_reconcile_service.dart';
import '../upcoming/materialize_upcoming_service.dart';
import '../spending/spending_granularity.dart';
import '../spending/spending_period_generator.dart';
import '../upcoming/deferred_ledger_reconcile_provider.dart';
import '../upcoming/materialize_upcoming_provider.dart';
import '../../features/transactions/application/transactions_list_notifier.dart';

/// Outcome of [LedgerAwareAppRefresh.runPullToRefresh].
enum LedgerAwareRefreshResult {
  /// Ran (or skipped callables only when server said clean); invalidation done.
  completed,

  /// No signed-in user.
  signedOut,

  /// Local wall-clock throttle blocked the whole operation.
  throttled,
}

const _kThrottleSeconds = 20;

String _throttleKey(String uid) => 'finko_ledger_refresh_last_wall_ms_$uid';

/// App-wide pull-to-refresh: throttle, server profile gate, callables, canonical invalidation.
///
/// See `docs/data-contract.md` / `docs/dashboard.md` revision logs.
class LedgerAwareAppRefresh {
  LedgerAwareAppRefresh({
    required this.repository,
    required this.materialize,
    required this.reconcile,
  });

  final FirestoreDataRepository repository;
  final MaterializeUpcomingService materialize;
  final DeferredLedgerReconcileService reconcile;

  /// Whether server timestamps imply deferred aggregates may still need reconcile.
  static bool needsReconcileFromProfile(
    DateTime? aggregateLastCompletedAt,
    DateTime? ledgerSourcesLastChangedAt,
  ) {
    final a = aggregateLastCompletedAt;
    final l = ledgerSourcesLastChangedAt;
    if (a == null || l == null) return true;
    return l.isAfter(a);
  }

  Future<LedgerAwareRefreshResult> runPullToRefresh(WidgetRef ref) async {
    final uid = ref.read(authUidProvider);
    if (uid == null) {
      _invalidateAggregateBackedProviders(ref);
      return LedgerAwareRefreshResult.signedOut;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _throttleKey(uid);
    final lastMs = prefs.getInt(key);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (lastMs != null && nowMs - lastMs < _kThrottleSeconds * 1000) {
      return LedgerAwareRefreshResult.throttled;
    }

    final profile = await repository.fetchUserProfileSync(uid);
    final timezone = profile?.timezone.trim();
    final tz = timezone != null && timezone.isNotEmpty ? timezone : null;
    final todayKey = ref.read(todayYyyyMmDdProvider);

    await materialize.forceRefreshIfSignedIn(uid, timezone: tz);

    final needReconcile = profile == null
        ? true
        : needsReconcileFromProfile(
            profile.aggregateLastCompletedAt,
            profile.ledgerSourcesLastChangedAt,
          );
    if (needReconcile) {
      await reconcile.forceReconcileIfSignedIn(uid, todayKey);
    }

    _invalidateAggregateBackedProviders(ref);

    await prefs.setInt(key, nowMs);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return LedgerAwareRefreshResult.completed;
  }
}

void _invalidateAggregateBackedProviders(WidgetRef ref) {
  ref.invalidate(accountsStreamProvider);
  ref.invalidate(userProfileStreamProvider);
  final dashYm = ref.read(dashboardYearMonthProvider);
  final curYm = ref.read(currentYearMonthProvider);
  ref.invalidate(monthlyTotalsForMonthStreamProvider(dashYm));
  if (dashYm != curYm) {
    ref.invalidate(monthlyTotalsForMonthStreamProvider(curYm));
  }
  ref.invalidate(currentMonthTotalsStreamProvider);
  ref.invalidate(recentTransactionsStreamProvider);
  ref.invalidate(upcomingTransactionsStreamProvider);
  ref.invalidate(futureDatedLedgerTransactionsStreamProvider);
  ref.invalidate(ledgerFromTodayForUpcomingMergeStreamProvider);
  ref.invalidate(recurringRulesStreamProvider);
  ref.invalidate(categoriesStreamProvider);
  ref.invalidate(dashboardUpcomingStripProvider);
  ref.invalidate(recurringMergedUpcomingProvider);
  ref.invalidate(netWorthSparklineSeriesProvider);
  ref.invalidate(transactionsListNotifierProvider);

  final today = ref.read(todayYyyyMmDdProvider);
  for (final g in SpendingGranularity.values) {
    final strip = buildSpendingPeriodStrip(
      granularity: g,
      todayYyyyMmDd: today,
    );
    if (strip.isEmpty) continue;
    ref.invalidate(
      transactionsForDateRangeStreamProvider((
        start: strip.first.startYyyyMmDd,
        end: strip.last.endYyyyMmDd,
      )),
    );
  }

  ref.invalidate(forexRatesForDateStreamProvider(today));
}

final ledgerAwareAppRefreshProvider = Provider<LedgerAwareAppRefresh>((ref) {
  return LedgerAwareAppRefresh(
    repository: ref.watch(firestoreDataRepositoryProvider),
    materialize: ref.watch(materializeUpcomingServiceProvider),
    reconcile: ref.watch(deferredLedgerReconcileServiceProvider),
  );
});
