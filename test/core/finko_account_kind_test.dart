import 'package:finko/core/data/models/finko_account.dart';
import 'package:finko/core/data/models/finko_account_kind.dart';
import 'package:finko/core/data/models/finko_enums.dart';
import 'package:flutter_test/flutter_test.dart';

FinkoAccount _acc(FinkoAccountType type, int balanceMinor, {int? main}) {
  final now = DateTime.utc(2026, 1, 1);
  return FinkoAccount(
    id: 'a',
    name: 'a',
    type: type,
    currency: 'MXN',
    balanceMinor: balanceMinor,
    balanceMinorMain: main,
    includeInNetCash: true,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('isLiabilityAccountType matches credit, loan, mortgage', () {
    expect(isLiabilityAccountType(FinkoAccountType.creditCard), isTrue);
    expect(isLiabilityAccountType(FinkoAccountType.loan), isTrue);
    expect(isLiabilityAccountType(FinkoAccountType.mortgage), isTrue);
    expect(isLiabilityAccountType(FinkoAccountType.checking), isFalse);
    expect(isLiabilityAccountType(FinkoAccountType.cash), isFalse);
  });

  test('netWorthFromAccountsMinor subtracts liability balances', () {
    final nw = netWorthFromAccountsMinor([
      _acc(FinkoAccountType.checking, 100_000),
      _acc(FinkoAccountType.creditCard, 20_000),
    ]);
    expect(nw, 80_000);
  });

  test(
    'netCashFromAccountsMinor uses signed balances for included accounts',
    () {
      final nc = netCashFromAccountsMinor([
        _acc(FinkoAccountType.checking, 50_000, main: 50_000),
        FinkoAccount(
          id: 'c',
          name: 'c',
          type: FinkoAccountType.creditCard,
          currency: 'MXN',
          balanceMinor: 10_000,
          balanceMinorMain: 10_000,
          includeInNetCash: true,
          sortOrder: 0,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ]);
      expect(nc, 40_000);
    },
  );

  test('openingBalanceDirectionForAccount inverts liability vs asset', () {
    expect(
      openingBalanceDirectionForAccount(FinkoAccountType.checking, 500),
      MoneyDirection.in_,
    );
    expect(
      openingBalanceDirectionForAccount(FinkoAccountType.creditCard, 500),
      MoneyDirection.out_,
    );
    expect(
      openingBalanceDirectionForAccount(FinkoAccountType.creditCard, -500),
      MoneyDirection.in_,
    );
  });
}
