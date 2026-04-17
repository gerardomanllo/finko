import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/core/data/models/ledger_transaction.dart';
import 'package:finko/core/formatting/ledger_transaction_amount.dart';
import 'package:flutter_test/flutter_test.dart';

LedgerTransaction _tx({
  required String id,
  required MoneyDirection direction,
  required int amountMinor,
  required String currency,
  int? amountMinorMain,
  String? categoryId,
  String accountId = 'acc1',
}) {
  final ph = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return LedgerTransaction(
    id: id,
    transactionDate: '2026-04-01',
    loadedAt: ph,
    amountMinor: amountMinor,
    direction: direction,
    currency: currency,
    accountId: accountId,
    categoryId: categoryId,
    type: LedgerTransactionKind.standard,
    amountMinorMain: amountMinorMain,
    createdAt: ph,
    updatedAt: ph,
  );
}

void main() {
  group('signedMinorMainComparableOrNull', () {
    test('uses amountMinorMain when set (foreign currency)', () {
      final t = _tx(
        id: '1',
        direction: MoneyDirection.out_,
        amountMinor: 1000,
        currency: 'USD',
        amountMinorMain: 18500,
      );
      expect(signedMinorMainComparableOrNull(t, 'MXN'), -18500);
    });

    test('falls back to amountMinor when currency matches main', () {
      final t = _tx(
        id: '1',
        direction: MoneyDirection.in_,
        amountMinor: 50000,
        currency: 'MXN',
        amountMinorMain: null,
      );
      expect(signedMinorMainComparableOrNull(t, 'MXN'), 50000);
    });

    test('returns null for foreign row without main conversion', () {
      final t = _tx(
        id: '1',
        direction: MoneyDirection.out_,
        amountMinor: 999,
        currency: 'EUR',
        amountMinorMain: null,
      );
      expect(signedMinorMainComparableOrNull(t, 'MXN'), isNull);
    });
  });

  group('sumSignedMinorMainComparableForAccount', () {
    test('sums only comparable rows on the account', () {
      final list = <LedgerTransaction>[
        _tx(
          id: 'a',
          direction: MoneyDirection.in_,
          amountMinor: 100,
          currency: 'MXN',
          amountMinorMain: null,
          accountId: 'A',
        ),
        _tx(
          id: 'b',
          direction: MoneyDirection.out_,
          amountMinor: 50,
          currency: 'USD',
          amountMinorMain: 900,
          accountId: 'A',
        ),
        _tx(
          id: 'c',
          direction: MoneyDirection.out_,
          amountMinor: 7,
          currency: 'EUR',
          amountMinorMain: null,
          accountId: 'A',
        ),
        _tx(
          id: 'd',
          direction: MoneyDirection.in_,
          amountMinor: 1,
          currency: 'MXN',
          amountMinorMain: null,
          accountId: 'B',
        ),
      ];
      expect(
        sumSignedMinorMainComparableForAccount(list, 'A', 'MXN'),
        100 - 900,
      );
    });
  });

  group('transactionAmountPrimarySecondary', () {
    test('foreign with main shows main signed primary and code secondary', () {
      final t = _tx(
        id: '1',
        direction: MoneyDirection.out_,
        amountMinor: 1000,
        currency: 'USD',
        amountMinorMain: 18500,
      );
      final r = transactionAmountPrimarySecondary(
        t: t,
        mainCurrency: 'MXN',
        locale: 'en',
      );
      expect(r.primary.startsWith('−'), isTrue);
      expect(r.secondary, isNotNull);
      expect(r.secondary!, contains('USD'));
    });

    test('foreign without main shows native signed primary only', () {
      final t = _tx(
        id: '1',
        direction: MoneyDirection.in_,
        amountMinor: 2500,
        currency: 'USD',
        amountMinorMain: null,
      );
      final r = transactionAmountPrimarySecondary(
        t: t,
        mainCurrency: 'MXN',
        locale: 'en',
      );
      expect(r.primary.startsWith('+'), isTrue);
      expect(r.secondary, isNull);
    });
  });
}
