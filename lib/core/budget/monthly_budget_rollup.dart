import '../data/models/finko_category.dart';
import '../data/models/finko_enums.dart';
import '../data/models/monthly_totals.dart';

/// Sum of `budgets.*.targetMinorMain` where `kind == expense`.
int totalExpenseBudgetMinor(Map<String, MonthlyBudgetEntry> budgets) {
  var sum = 0;
  for (final e in budgets.values) {
    if (e.kind == BudgetKind.expense) {
      sum += e.targetMinorMain;
    }
  }
  return sum;
}

/// Sum of `budgets.*.targetMinorMain` where `kind == income`.
int totalIncomeBudgetMinor(Map<String, MonthlyBudgetEntry> budgets) {
  var sum = 0;
  for (final e in budgets.values) {
    if (e.kind == BudgetKind.income) {
      sum += e.targetMinorMain;
    }
  }
  return sum;
}

/// Sum of [budgets] **targets** for each Firestore **income** category in
/// [categories]. Missing `budgets.{id}` counts as 0.
///
/// Used on `/budgets` for the **Earnings** compact card: **X** in product copy
/// (to earn vs **Y** = [`MonthlyTotals.incomeMinorMain`]).
int incomeCategoryBudgetTargetMinor(
  Map<String, MonthlyBudgetEntry> budgets,
  Iterable<FinkoCategory> categories,
) {
  var sum = 0;
  for (final c in categories) {
    if (c.kind != CategoryKind.income) continue;
    final row = budgets[c.id];
    if (row == null) continue;
    sum += row.targetMinorMain;
  }
  return sum;
}

/// Signed [`MonthlyTotals.byCategoryMinorMain`] net → positive expense minor (outflows).
int positiveExpenseMinorFromSignedNet(int signedNet) {
  return signedNet < 0 ? -signedNet : 0;
}

/// Signed net → positive income minor (inflows attributed to category).
int positiveIncomeMinorFromSignedNet(int signedNet) {
  return signedNet > 0 ? signedNet : 0;
}

/// Budget target and positive spend for all expense categories with
/// [FinkoCategory.isFixedExpense].
({int budgetedMinor, int spentMinor}) fixedExpensesBudgetAndSpent(
  MonthlyTotals m,
  Map<String, MonthlyBudgetEntry> budgets,
  Iterable<FinkoCategory> categories,
) {
  var budgeted = 0;
  var spent = 0;
  for (final c in categories) {
    if (c.kind != CategoryKind.expense || !c.isFixedExpense) continue;
    budgeted += budgets[c.id]?.targetMinorMain ?? 0;
    final raw = m.byCategoryMinorMain[c.id] ?? 0;
    spent += positiveExpenseMinorFromSignedNet(raw);
  }
  return (budgetedMinor: budgeted, spentMinor: spent);
}
