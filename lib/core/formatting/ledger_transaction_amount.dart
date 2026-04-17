import '../data/models/finko_enums.dart';
import '../data/models/ledger_transaction.dart';
import 'money_format.dart';

/// Signed effect in **main-currency** minor units when comparable to [mainCurrency].
///
/// Uses [LedgerTransaction.amountMinorMain] when set (Cloud Functions / client audit).
/// When null and the row’s [LedgerTransaction.currency] equals [mainCurrency], uses
/// [LedgerTransaction.amountMinor] (same units as spending’s `expenseMinorComparable` fallback).
///
/// Returns `null` when a foreign-currency row has no main conversion yet — callers must
/// not add that to a main-currency total without FX.
int? signedMinorMainComparableOrNull(LedgerTransaction t, String mainCurrency) {
  if (t.amountMinorMain != null) {
    final v = t.amountMinorMain!;
    return t.direction == MoneyDirection.in_ ? v : -v;
  }
  if (t.currency == mainCurrency) {
    final v = t.amountMinor;
    return t.direction == MoneyDirection.in_ ? v : -v;
  }
  return null;
}

/// Signed effect in the row’s own [LedgerTransaction.currency] (always [amountMinor]).
int signedMinorNative(LedgerTransaction t) {
  final v = t.amountMinor;
  return t.direction == MoneyDirection.in_ ? v : -v;
}

/// Sum of [signedMinorMainComparableOrNull] for rows on [accountId] (skips incomparable).
int sumSignedMinorMainComparableForAccount(
  Iterable<LedgerTransaction> list,
  String accountId,
  String mainCurrency,
) {
  var sum = 0;
  for (final t in list) {
    if (t.accountId != accountId) continue;
    final s = signedMinorMainComparableOrNull(t, mainCurrency);
    if (s != null) sum += s;
  }
  return sum;
}

String signedMoneyLabel(int minor, String currency, String locale) {
  final sign = minor >= 0 ? '+' : '−';
  return '$sign${formatMinorUnits(minor.abs(), currency, locale)}';
}

/// Primary / secondary line for compact rows (aligned with transactions list semantics).
({String primary, String? secondary}) transactionAmountPrimarySecondary({
  required LedgerTransaction t,
  required String mainCurrency,
  required String locale,
}) {
  final mainSigned = signedMinorMainComparableOrNull(t, mainCurrency);
  if (mainSigned != null) {
    final primary = signedMoneyLabel(mainSigned, mainCurrency, locale);
    final String? secondary =
        t.currency != mainCurrency && t.amountMinorMain != null
        ? formatMinorUnitsWithCode(t.amountMinor, t.currency, locale)
        : null;
    return (primary: primary, secondary: secondary);
  }
  final native = signedMinorNative(t);
  return (
    primary: signedMoneyLabel(native, t.currency, locale),
    secondary: null,
  );
}
