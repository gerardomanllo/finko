import 'finko_account.dart';
import 'finko_enums.dart';

/// Direction for an opening-balance adjustment (non-zero starting balance).
///
/// **Assets:** positive start = money in the account (`in`); negative = overdraft (`out`).
/// **Liabilities:** positive start = debt owed (`out` increases owed); negative = credit
/// balance / overpayment (`in`).
MoneyDirection openingBalanceDirectionForAccount(
  FinkoAccountType type,
  int startingBalanceMinor,
) {
  if (startingBalanceMinor >= 0) {
    return isLiabilityAccountType(type)
        ? MoneyDirection.out_
        : MoneyDirection.in_;
  }
  return isLiabilityAccountType(type)
      ? MoneyDirection.in_
      : MoneyDirection.out_;
}

/// Whether [FinkoAccountType] uses **liability** balance semantics: positive
/// stored balance = amount owed (see docs/data-model.md).
bool isLiabilityAccountType(FinkoAccountType type) {
  return switch (type) {
    FinkoAccountType.creditCard ||
    FinkoAccountType.loan ||
    FinkoAccountType.mortgage => true,
    FinkoAccountType.cash ||
    FinkoAccountType.checking ||
    FinkoAccountType.savings ||
    FinkoAccountType.investment => false,
  };
}

/// Main-currency minor contribution to **net worth** (assets add, liabilities subtract).
int signedBalanceForNetWorthMinor(FinkoAccount account) {
  final b = account.balanceMinorMain ?? account.balanceMinor;
  return isLiabilityAccountType(account.type) ? -b : b;
}

/// Same signing for accounts included in **net cash** rollups.
int signedBalanceForNetCashMinor(FinkoAccount account) {
  return signedBalanceForNetWorthMinor(account);
}

int netWorthFromAccountsMinor(Iterable<FinkoAccount> accounts) {
  var sum = 0;
  for (final a in accounts) {
    sum += signedBalanceForNetWorthMinor(a);
  }
  return sum;
}

int netCashFromAccountsMinor(Iterable<FinkoAccount> accounts) {
  var sum = 0;
  for (final a in accounts) {
    if (a.includeInNetCash) {
      sum += signedBalanceForNetCashMinor(a);
    }
  }
  return sum;
}
