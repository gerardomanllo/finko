import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/monthly_totals.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/spending/spending_granularity.dart';
import '../../../core/spending/spending_period_descriptor.dart';
import '../../../core/spending/spending_rollups.dart';

/// Combines one or more `monthlyTotals/{yyyy-mm}` streams for the months
/// touched by [period] ([`docs/data-contract.md`] Spending).
final spendingMergedMonthlyRollupProvider =
    Provider.family<AsyncValue<MergedMonthlyRollup>, SpendingPeriodDescriptor>((
      ref,
      period,
    ) {
      final yms = yearMonthsForSpendingPeriod(period);
      final asyncs = <AsyncValue<MonthlyTotals?>>[
        for (final ym in yms)
          ref.watch(monthlyTotalsForMonthStreamProvider(ym)),
      ];
      return _combineMonthlyAsyncs(asyncs);
    });

AsyncValue<MergedMonthlyRollup> _combineMonthlyAsyncs(
  List<AsyncValue<MonthlyTotals?>> parts,
) {
  for (final p in parts) {
    final err = p.whenOrNull(error: (Object e, StackTrace st) => (e, st));
    if (err != null) {
      return AsyncValue.error(err.$1, err.$2);
    }
  }
  var loading = false;
  for (final p in parts) {
    p.when(data: (_) {}, error: (_, _) {}, loading: () => loading = true);
  }
  if (loading) {
    return const AsyncValue.loading();
  }
  final list = [for (final p in parts) p.valueOrNull];
  return AsyncValue.data(mergeMonthlyTotals(list));
}

/// Income and expense for a period card: **week** uses [`sumDayIncomeExpenseInRange`];
/// other granularities use merged month totals.
final spendingPeriodIncomeExpenseProvider =
    Provider.family<
      AsyncValue<({int income, int expense})>,
      SpendingPeriodDescriptor
    >((ref, period) {
      if (period.granularity == SpendingGranularity.week) {
        final yms = yearMonthsForSpendingPeriod(period);
        final asyncs = <AsyncValue<MonthlyTotals?>>[
          for (final ym in yms)
            ref.watch(monthlyTotalsForMonthStreamProvider(ym)),
        ];
        final combined = _combineMonthlyAsyncs(asyncs);
        return combined.when(
          data: (_) {
            final map = <String, MonthlyTotals?>{
              for (var i = 0; i < yms.length; i++)
                yms[i]: asyncs[i].valueOrNull,
            };
            final r = sumDayIncomeExpenseInRange(
              startYyyyMmDd: period.startYyyyMmDd,
              endYyyyMmDd: period.endYyyyMmDd,
              totalsByYearMonth: map,
            );
            return AsyncValue.data((
              income: r.incomeMinorMain,
              expense: r.expenseMinorMain,
            ));
          },
          loading: () => const AsyncValue.loading(),
          error: (e, st) => AsyncValue.error(e, st),
        );
      }
      final merged = ref.watch(spendingMergedMonthlyRollupProvider(period));
      return merged.when(
        data: (m) {
          return AsyncValue.data((
            income: m.incomeMinorMain,
            expense: m.expenseMinorMain,
          ));
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });
