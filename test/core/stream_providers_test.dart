import 'package:finko/core/auth/firebase_auth_providers.dart';
import 'package:finko/core/data/models/monthly_totals.dart';
import 'package:finko/core/data/providers/finko_stream_providers.dart';
import 'package:finko/core/data/repositories/firestore_data_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_firestore_data_repository.dart';

void main() {
  test('accountsStreamProvider emits empty list when uid is null', () async {
    final container = ProviderContainer(
      overrides: [
        authUidProvider.overrideWith((ref) => null),
        firestoreDataRepositoryProvider.overrideWithValue(
          FakeFirestoreDataRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(accountsStreamProvider, (previous, next) {});
    await Future<void>.delayed(Duration.zero);
    final async = container.read(accountsStreamProvider);
    expect(async.hasValue, isTrue);
    expect(async.value, <dynamic>[]);
    sub.close();
  });

  test(
    'netWorthSparklineSeriesProvider forward-fills missing day values',
    () async {
      final march = MonthlyTotals(
        yearMonth: '2026-03',
        incomeMinorMain: 0,
        expenseMinorMain: 0,
        byCategoryMinorMain: const {},
        budgets: const {},
        days: const {'29': MonthlyDayRollup(netWorthEodMinorMain: 1000)},
      );
      final april = MonthlyTotals(
        yearMonth: '2026-04',
        incomeMinorMain: 0,
        expenseMinorMain: 0,
        byCategoryMinorMain: const {},
        budgets: const {},
        days: const {'02': MonthlyDayRollup(netWorthEodMinorMain: 1300)},
      );
      final container = ProviderContainer(
        overrides: [
          nowProvider.overrideWith((ref) => DateTime(2026, 4, 2)),
          monthlyTotalsForMonthStreamProvider(
            '2026-03',
          ).overrideWith((ref) => Stream.value(march)),
          monthlyTotalsForMonthStreamProvider(
            '2026-04',
          ).overrideWith((ref) => Stream.value(april)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        netWorthSparklineSeriesProvider,
        (previous, next) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      final series = container.read(netWorthSparklineSeriesProvider);
      expect(series.length, 30);
      expect(series[25], 1000); // 2026-03-29 explicit point
      expect(series[26], 1000); // 2026-03-30 forward-filled
      expect(series[27], 1000); // 2026-03-31 forward-filled
      expect(series[28], 1000); // 2026-04-01 forward-filled
      expect(series[29], 1300); // 2026-04-02 explicit point
    },
  );
}
