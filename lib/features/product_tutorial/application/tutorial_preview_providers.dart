import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/models/monthly_totals.dart';
import '../../../core/data/models/upcoming_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/spending/spending_period_descriptor.dart';
import '../../../core/spending/spending_rollups.dart';
import '../../spending/presentation/spending_providers.dart';
import 'product_tutorial_controller.dart';
import 'tutorial_preview_data.dart';

/// Standalone preview ledger rows for transactions list fallback.
final tourPreviewLedgerTransactionsProvider =
    Provider<List<LedgerTransaction>>((ref) {
      return buildTutorialPreviewLedgerTransactions(ref);
    });

/// Recent dashboard rows with tour preview fallback.
final tourAwareRecentTransactionsProvider = Provider<List<LedgerTransaction>>((
  ref,
) {
  final real = ref.watch(recentTransactionsStreamProvider).valueOrNull ?? [];
  if (!ref.watch(productTutorialActiveProvider) || real.isNotEmpty) {
    return real;
  }
  return buildTutorialPreviewLedgerTransactions(ref);
});

/// Current dashboard month totals with tour preview fallback.
final tourAwareDashboardMonthTotalsProvider = Provider<MonthlyTotals?>((ref) {
  final ym = ref.watch(dashboardYearMonthProvider);
  final real = ref
      .watch(monthlyTotalsForMonthStreamProvider(ym))
      .valueOrNull;
  if (!ref.watch(productTutorialActiveProvider) || real != null) {
    return real;
  }
  return buildTutorialPreviewMonthlyTotals(ref, ym);
});

/// Budgets screen month totals with tour preview fallback.
final tourAwareMonthTotalsProvider = Provider.family<MonthlyTotals?, String>((
  ref,
  ym,
) {
  final real = ref.watch(monthlyTotalsForMonthStreamProvider(ym)).valueOrNull;
  if (!ref.watch(productTutorialActiveProvider) || real != null) {
    return real;
  }
  return buildTutorialPreviewMonthlyTotals(ref, ym);
});

/// Upcoming list (recurring / dashboard) with tour preview fallback.
final tourAwareUpcomingTransactionsProvider =
    Provider<List<UpcomingTransaction>>((ref) {
      final real =
          ref.watch(upcomingTransactionsStreamProvider).valueOrNull ?? [];
      if (!ref.watch(productTutorialActiveProvider) || real.isNotEmpty) {
        return real;
      }
      return buildTutorialPreviewUpcoming(ref);
    });

/// Dashboard upcoming strip with tour preview fallback.
final tourAwareDashboardUpcomingProvider = Provider<List<UpcomingTransaction>>((
  ref,
) {
  final real = ref.watch(dashboardUpcomingStripProvider).valueOrNull ?? [];
  if (!ref.watch(productTutorialActiveProvider) || real.isNotEmpty) {
    return real;
  }
  return buildTutorialPreviewUpcoming(ref);
});

/// Recurring merged upcoming with tour preview fallback.
final tourAwareRecurringMergedProvider = Provider<List<UpcomingTransaction>>((
  ref,
) {
  final real = ref.watch(recurringMergedUpcomingProvider).valueOrNull ?? [];
  if (!ref.watch(productTutorialActiveProvider) || real.isNotEmpty) {
    return real;
  }
  return buildTutorialPreviewUpcoming(ref);
});

/// Merged monthly rollup for spending donut with tour preview fallback.
final tourAwareSpendingMergedRollupProvider = Provider.family<
  AsyncValue<MergedMonthlyRollup>,
  SpendingPeriodDescriptor
>((ref, period) {
  final real = ref.watch(spendingMergedMonthlyRollupProvider(period));
  if (!ref.watch(productTutorialActiveProvider)) return real;
  return real.when(
    data: (merged) {
      if (merged.expenseMinorMain > 0 ||
          merged.byCategoryMinorMain.isNotEmpty) {
        return real;
      }
      final yms = yearMonthsForSpendingPeriod(period);
      if (yms.isEmpty) return real;
      final preview = buildTutorialPreviewMonthlyTotals(ref, yms.first);
      if (preview == null) return real;
      return AsyncValue.data(mergeMonthlyTotals([preview]));
    },
    loading: () => real,
    error: (e, st) => real,
  );
});

/// Spending date-range window with tour preview fallback.
final tourAwareTransactionsForRangeProvider =
    Provider.family<List<LedgerTransaction>, ({String start, String end})>((
      ref,
      range,
    ) {
      final real =
          ref
              .watch(transactionsForDateRangeStreamProvider(range))
              .valueOrNull ??
          [];
      if (!ref.watch(productTutorialActiveProvider) || real.isNotEmpty) {
        return real;
      }
      return buildTutorialPreviewLedgerTransactions(ref);
    });
