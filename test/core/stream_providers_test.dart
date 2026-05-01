import 'package:finko/core/auth/firebase_auth_providers.dart';
import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/core/data/models/ledger_transaction.dart';
import 'package:finko/core/data/models/monthly_totals.dart';
import 'package:finko/core/data/models/recurring_rule.dart';
import 'package:finko/core/data/models/upcoming_transaction.dart';
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
        days: const {'29': MonthlyDayRollup(netWorthEodMinorMain: 1000)},
      );
      final april = MonthlyTotals(
        yearMonth: '2026-04',
        incomeMinorMain: 0,
        expenseMinorMain: 0,
        byCategoryMinorMain: const {},
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

  group('mergeUpcomingForUi', () {
    final t0 = DateTime.utc(2026, 4, 10, 12);

    UpcomingTransaction upcoming(
      String id,
      String ymd, {
      String? recurringRuleId,
    }) {
      return UpcomingTransaction(
        id: id,
        transactionDate: ymd,
        kind: UpcomingKind.standard,
        amountMinor: 100,
        direction: MoneyDirection.out_,
        currency: 'MXN',
        accountId: 'a1',
        categoryId: 'c1',
        recurringRuleId: recurringRuleId,
        loadedAt: t0,
        updatedAt: t0,
      );
    }

    RecurringRule rule(String id, String nextYmd) {
      return RecurringRule(
        id: id,
        name: 'Rule',
        kind: UpcomingKind.standard,
        amountMinor: 200,
        direction: MoneyDirection.in_,
        currency: 'MXN',
        categoryId: 'c1',
        accountId: 'a1',
        cadence: RecurringCadence.monthly,
        active: true,
        nextTransactionDate: nextYmd,
        createdAt: t0,
        updatedAt: t0,
      );
    }

    LedgerTransaction ledgerFuture(String id, String ymd) {
      return LedgerTransaction(
        id: id,
        transactionDate: ymd,
        loadedAt: t0,
        amountMinor: 50,
        direction: MoneyDirection.out_,
        currency: 'MXN',
        accountId: 'a1',
        categoryId: 'c1',
        type: LedgerTransactionKind.standard,
        createdAt: t0,
        updatedAt: t0,
      );
    }

    test('includeDueToday false omits upcoming and rules due today', () {
      const today = '2026-04-15';
      final merged = mergeUpcomingForUi(
        [
          upcoming('u1', '2026-04-15'),
          upcoming('u2', '2026-04-20'),
        ],
        [rule('r1', '2026-04-15')],
        today,
        ledgerFuture: [ledgerFuture('tx1', '2026-04-18')],
        includeDueToday: false,
      );
      expect(merged.map((e) => e.id), ['ledger_preview_tx1', 'u2']);
      expect(merged.any((e) => e.id == 'u1'), isFalse);
    });

    test('includeDueToday true keeps today and merges ledger preview', () {
      const today = '2026-04-15';
      final merged = mergeUpcomingForUi(
        [
          upcoming('u1', '2026-04-15'),
          upcoming('u2', '2026-04-20'),
        ],
        [rule('r1', '2026-04-16')],
        today,
        ledgerFuture: [ledgerFuture('tx1', '2026-04-18')],
        includeDueToday: true,
      );
      expect(merged.map((e) => e.id), [
        'u1',
        'recurring_preview_r1',
        'ledger_preview_tx1',
        'u2',
      ]);
    });

    test('includeDueToday true merges ledger preview dated today', () {
      const today = '2026-04-15';
      final merged = mergeUpcomingForUi(
        [upcoming('u1', '2026-04-20')],
        const [],
        today,
        ledgerFuture: [ledgerFuture('txToday', '2026-04-15')],
        includeDueToday: true,
      );
      expect(merged.map((e) => e.id), ['ledger_preview_txToday', 'u1']);
    });

    test('includeDueToday false skips ledger preview dated today', () {
      const today = '2026-04-15';
      final merged = mergeUpcomingForUi(
        [upcoming('u1', '2026-04-20')],
        const [],
        today,
        ledgerFuture: [ledgerFuture('txToday', '2026-04-15')],
        includeDueToday: false,
      );
      expect(merged.map((e) => e.id), ['u1']);
    });
  });
}
