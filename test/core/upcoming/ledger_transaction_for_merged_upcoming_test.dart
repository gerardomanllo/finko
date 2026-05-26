import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/core/data/models/ledger_transaction.dart';
import 'package:finko/core/data/models/upcoming_transaction.dart';
import 'package:finko/core/upcoming/ledger_transaction_for_merged_upcoming.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ledger_preview id maps to ledger row by transaction id', () {
    final t = _ledger('tx1');
    final u = UpcomingTransaction.fromLedgerPreview(t);
    expect(ledgerTransactionForMergedUpcoming(u, [t])?.id, 'tx1');
  });

  test('sourceUpcomingId links materialized ledger to upcoming id', () {
    final upcomingId = 'up1';
    final leg = _ledger('L1', sourceUpcomingId: upcomingId);
    final u = _upcoming(upcomingId);
    expect(ledgerTransactionForMergedUpcoming(u, [leg])?.id, 'L1');
  });

  test('returns null when no ledger match', () {
    final u = _upcoming('orphan');
    expect(ledgerTransactionForMergedUpcoming(u, const []), isNull);
  });
}

UpcomingTransaction _upcoming(String id) {
  final n = DateTime.utc(2026, 1, 1);
  return UpcomingTransaction(
    id: id,
    transactionDate: '2026-05-20',
    kind: UpcomingKind.standard,
    amountMinor: 100,
    direction: MoneyDirection.out_,
    currency: 'MXN',
    accountId: 'a1',
    categoryId: 'c1',
    loadedAt: n,
    updatedAt: n,
  );
}

LedgerTransaction _ledger(String id, {String? sourceUpcomingId}) {
  final n = DateTime.utc(2026, 1, 1);
  return LedgerTransaction(
    id: id,
    transactionDate: '2026-05-20',
    loadedAt: n,
    amountMinor: 100,
    direction: MoneyDirection.out_,
    currency: 'MXN',
    accountId: 'a1',
    categoryId: 'c1',
    type: LedgerTransactionKind.standard,
    sourceUpcomingId: sourceUpcomingId,
    createdAt: n,
    updatedAt: n,
  );
}
