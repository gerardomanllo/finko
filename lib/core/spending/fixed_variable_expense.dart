import '../data/models/finko_category.dart';
import '../data/models/finko_enums.dart';

/// Category ids that count toward fixed expense analytics.
Set<String> fixedExpenseCategoryIds(Iterable<FinkoCategory> categories) {
  return {
    for (final c in categories)
      if (c.kind == CategoryKind.expense && c.isFixedExpense) c.id,
  };
}

int _sumPositiveSlicesForIds(
  Map<String, int> positiveByCategory,
  Set<String> categoryIds,
) {
  var sum = 0;
  for (final id in categoryIds) {
    sum += positiveByCategory[id] ?? 0;
  }
  return sum;
}

int _sumSignedExpenseForIds(
  Map<String, int> signedByCategory,
  Set<String> categoryIds,
) {
  var sum = 0;
  for (final id in categoryIds) {
    final raw = signedByCategory[id] ?? 0;
    if (raw < 0) sum += -raw;
  }
  return sum;
}

/// Positive expense minor (main) attributed to fixed vs variable, from merged
/// [`byCategoryMinorMain`] (signed: outflows negative for expense categories) and
/// [totalExpenseMinorMain] (positive, from `expenseMinorMain`).
({int fixedMinorMain, int variableMinorMain}) splitFixedVariableExpense({
  required int totalExpenseMinorMain,
  required Map<String, int> byCategoryMinorMain,
  required Set<String> fixedCategoryIds,
}) {
  final fixedSpent = _sumSignedExpenseForIds(
    byCategoryMinorMain,
    fixedCategoryIds,
  );
  final cappedFixed = fixedSpent.clamp(0, totalExpenseMinorMain);
  final variable = (totalExpenseMinorMain - cappedFixed).clamp(0, 1 << 62);
  return (fixedMinorMain: cappedFixed, variableMinorMain: variable);
}

/// Fixed/variable strip for **month** (and other merged totals) when the donut
/// uses [positiveExpenseByCategoryId]: **fixed** = sum of slices for
/// [fixedCategoryIds]; **variable** = `totalExpenseMinorMain - fixed` so the
/// accordion matches donut wedges (KB-002: signed `byCategoryMinorMain` alone
/// can disagree).
({int fixedMinorMain, int variableMinorMain})
splitFixedVariableFromPositiveSlices({
  required int totalExpenseMinorMain,
  required Map<String, int> positiveExpenseByCategoryMinorMain,
  required Set<String> fixedCategoryIds,
}) {
  final fixedSlice = _sumPositiveSlicesForIds(
    positiveExpenseByCategoryMinorMain,
    fixedCategoryIds,
  );
  final fixedMinorMain = fixedSlice.clamp(0, totalExpenseMinorMain);
  final variableMinorMain = (totalExpenseMinorMain - fixedMinorMain).clamp(
    0,
    1 << 62,
  );
  return (fixedMinorMain: fixedMinorMain, variableMinorMain: variableMinorMain);
}
