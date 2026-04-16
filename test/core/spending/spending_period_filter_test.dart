import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/core/data/models/ledger_transaction.dart';
import 'package:finko/core/spending/spending_granularity.dart';
import 'package:finko/core/spending/spending_period_descriptor.dart';
import 'package:finko/core/spending/spending_period_filter.dart';
import 'package:flutter_test/flutter_test.dart';

LedgerTransaction _tx(
  String id,
  String date, {
  MoneyDirection dir = MoneyDirection.out_,
}) {
  final ph = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return LedgerTransaction(
    id: id,
    transactionDate: date,
    loadedAt: ph,
    amountMinor: 100,
    direction: dir,
    currency: 'MXN',
    accountId: 'a',
    categoryId: 'c',
    type: LedgerTransactionKind.standard,
    memo: null,
    transferGroupId: null,
    linkedTransactionId: null,
    sourceUpcomingId: null,
    amountMinorMain: null,
    fxRateDateUsed: null,
    createdAt: ph,
    updatedAt: ph,
  );
}

void main() {
  test('periodsWithTransactions keeps only periods touched by a tx', () {
    final p1 = SpendingPeriodDescriptor(
      granularity: SpendingGranularity.month,
      startYyyyMmDd: '2026-01-01',
      endYyyyMmDd: '2026-01-31',
      key: 'm1',
    );
    final p2 = SpendingPeriodDescriptor(
      granularity: SpendingGranularity.month,
      startYyyyMmDd: '2026-02-01',
      endYyyyMmDd: '2026-02-28',
      key: 'm2',
    );
    final p3 = SpendingPeriodDescriptor(
      granularity: SpendingGranularity.month,
      startYyyyMmDd: '2026-03-01',
      endYyyyMmDd: '2026-03-31',
      key: 'm3',
    );
    final txs = [_tx('1', '2026-02-15')];
    final out = periodsWithTransactions([p1, p2, p3], txs);
    expect(out.map((e) => e.key).toList(), ['m2']);
  });
}
