/// System category from onboarding ([`lib/features/onboarding/domain/onboarding_models.dart`]).
const String kFixedExpensesCategoryId = 'fixed-expenses';

/// Positive expense minor (main) attributed to fixed vs variable, from merged
/// [`byCategoryMinorMain`] (signed: outflows negative for expense categories) and
/// [totalExpenseMinorMain] (positive, from `expenseMinorMain`).
({int fixedMinorMain, int variableMinorMain}) splitFixedVariableExpense({
  required int totalExpenseMinorMain,
  required Map<String, int> byCategoryMinorMain,
}) {
  final fixedRaw = byCategoryMinorMain[kFixedExpensesCategoryId] ?? 0;
  // Expense categories accumulate negative deltas (see `ledgerAggregateMath.ts`).
  final fixedSpent = fixedRaw >= 0 ? 0 : -fixedRaw;
  final cappedFixed = fixedSpent.clamp(0, totalExpenseMinorMain);
  final variable = (totalExpenseMinorMain - cappedFixed).clamp(0, 1 << 62);
  return (fixedMinorMain: cappedFixed, variableMinorMain: variable);
}

/// Fixed/variable strip for **month** (and other merged totals) when the donut
/// uses [positiveExpenseByCategoryId]: **fixed** = Fixed Expenses slice only;
/// **variable** = `totalExpenseMinorMain - fixed` so the accordion matches
/// donut wedges (KB-002: signed `byCategoryMinorMain` alone can disagree).
({int fixedMinorMain, int variableMinorMain})
splitFixedVariableFromPositiveSlices({
  required int totalExpenseMinorMain,
  required Map<String, int> positiveExpenseByCategoryMinorMain,
}) {
  final fixedSlice =
      positiveExpenseByCategoryMinorMain[kFixedExpensesCategoryId] ?? 0;
  final fixedMinorMain = fixedSlice.clamp(0, totalExpenseMinorMain);
  final variableMinorMain = (totalExpenseMinorMain - fixedMinorMain).clamp(
    0,
    1 << 62,
  );
  return (fixedMinorMain: fixedMinorMain, variableMinorMain: variableMinorMain);
}
