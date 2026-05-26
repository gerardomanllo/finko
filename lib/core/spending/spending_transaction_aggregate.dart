import '../data/models/finko_enums.dart';
import '../data/models/ledger_transaction.dart';
import '../formatting/money_format.dart';

/// Outflow totals for donut / top list (prefers **main** minor; falls back to
/// [LedgerTransaction.amountMinor] when currency matches [mainCurrency]).
class SpendingTxRollup {
  const SpendingTxRollup({
    required this.totalExpenseMinorMain,
    required this.byCategoryMinorMain,
    required this.topOutflows,
  });

  final int totalExpenseMinorMain;

  /// categoryId → positive expense (comparable minor units).
  final Map<String, int> byCategoryMinorMain;

  /// Largest outflows (non-transfer legs), newest first when amounts tie.
  final List<LedgerTransaction> topOutflows;
}

bool _countsForSpendingAggregate(LedgerTransaction t) {
  if (t.direction != MoneyDirection.out_) return false;
  if (t.type == LedgerTransactionKind.transferLeg) return false;
  return true;
}

/// Prefer `amountMinorMain`; if null, use `amountMinor` only when [t.currency]
/// equals [mainCurrency] (same-unit fallback for rows CF has not stamped yet).
int? expenseMinorComparable(LedgerTransaction t, String mainCurrency) {
  if (!_countsForSpendingAggregate(t)) return null;
  final main = t.amountMinorMain;
  if (main != null && main > 0) return main;
  if (t.currency == mainCurrency && t.amountMinor > 0) return t.amountMinor;
  return null;
}

/// Aggregates expense outflows in range for donut / accordion / top list.
SpendingTxRollup aggregateSpendingTransactions(
  List<LedgerTransaction> transactions, {
  required String mainCurrency,
  int topCount = 4,
}) {
  final byCat = <String, int>{};
  var total = 0;
  final out = <LedgerTransaction>[];
  for (final t in transactions) {
    final minor = expenseMinorComparable(t, mainCurrency);
    if (minor == null) continue;
    total += minor;
    final cid = t.categoryId;
    byCat[cid] = (byCat[cid] ?? 0) + minor;
    out.add(t);
  }
  out.sort((a, b) {
    final am = expenseMinorComparable(a, mainCurrency) ?? 0;
    final bm = expenseMinorComparable(b, mainCurrency) ?? 0;
    final c = bm.compareTo(am);
    if (c != 0) return c;
    return b.transactionDate.compareTo(a.transactionDate);
  });
  final top = out.take(topCount).toList();
  return SpendingTxRollup(
    totalExpenseMinorMain: total,
    byCategoryMinorMain: byCat,
    topOutflows: top,
  );
}

/// Fixed / variable from transaction-derived category map (positive amounts).
({int fixedMinorMain, int variableMinorMain})
splitFixedVariableFromPositiveByCategory({
  required int totalExpenseMinorMain,
  required Map<String, int> byCategoryPositiveMinorMain,
  required Set<String> fixedCategoryIds,
}) {
  var fixedSpent = 0;
  for (final id in fixedCategoryIds) {
    fixedSpent += byCategoryPositiveMinorMain[id] ?? 0;
  }
  final cappedFixed = fixedSpent.clamp(0, totalExpenseMinorMain);
  final variable = nonNegativeMinor(totalExpenseMinorMain - cappedFixed);
  return (fixedMinorMain: cappedFixed, variableMinorMain: variable);
}
