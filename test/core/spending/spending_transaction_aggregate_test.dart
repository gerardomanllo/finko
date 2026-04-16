import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/core/data/models/ledger_transaction.dart';
import 'package:finko/core/spending/spending_transaction_aggregate.dart';
import 'package:flutter_test/flutter_test.dart';

LedgerTransaction _out(
  String id,
  String date, {
  int? amountMinorMain,
  int amountMinor = 5000,
  String currency = 'MXN',
}) {
  final ph = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return LedgerTransaction(
    id: id,
    transactionDate: date,
    loadedAt: ph,
    amountMinor: amountMinor,
    direction: MoneyDirection.out_,
    currency: currency,
    accountId: 'a',
    categoryId: 'c1',
    type: LedgerTransactionKind.standard,
    memo: null,
    transferGroupId: null,
    linkedTransactionId: null,
    sourceUpcomingId: null,
    amountMinorMain: amountMinorMain,
    fxRateDateUsed: null,
    createdAt: ph,
    updatedAt: ph,
  );
}

void main() {
  test(
    'aggregateSpendingTransactions uses amountMinor when main null and currency matches',
    () {
      final txs = [
        _out('1', '2026-04-10', amountMinorMain: null, amountMinor: 3000),
        _out('2', '2026-04-11', amountMinorMain: 1000),
      ];
      final r = aggregateSpendingTransactions(txs, mainCurrency: 'MXN');
      expect(r.totalExpenseMinorMain, 4000);
      expect(r.topOutflows.length, 2);
      expect(r.topOutflows.first.id, '1');
    },
  );

  test(
    'aggregateSpendingTransactions skips foreign currency when main is null',
    () {
      final txs = [
        _out(
          '1',
          '2026-04-10',
          amountMinorMain: null,
          amountMinor: 3000,
          currency: 'USD',
        ),
      ];
      final r = aggregateSpendingTransactions(txs, mainCurrency: 'MXN');
      expect(r.totalExpenseMinorMain, 0);
      expect(r.topOutflows, isEmpty);
    },
  );
}
