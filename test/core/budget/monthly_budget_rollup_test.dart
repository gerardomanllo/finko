import 'package:finko/core/budget/monthly_budget_rollup.dart';
import 'package:finko/core/data/models/finko_category.dart';
import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/core/data/models/monthly_totals.dart';
import 'package:flutter_test/flutter_test.dart';

MonthlyTotals _month({
  Map<String, int> byCategory = const {},
  int incomeMinorMain = 0,
  int expenseMinorMain = 0,
}) {
  return MonthlyTotals(
    yearMonth: '2026-04',
    incomeMinorMain: incomeMinorMain,
    expenseMinorMain: expenseMinorMain,
    byCategoryMinorMain: byCategory,
    days: const {},
  );
}

void main() {
  group('monthly_budget_rollup', () {
    test('totalExpenseBudgetMinor sums expense kind only', () {
      final budgets = {
        'a': const MonthlyBudgetEntry(
          targetMinorMain: 100,
          kind: BudgetKind.expense,
        ),
        'b': const MonthlyBudgetEntry(
          targetMinorMain: 50,
          kind: BudgetKind.income,
        ),
      };
      expect(totalExpenseBudgetMinor(budgets), 100);
    });

    test('totalIncomeBudgetMinor sums income kind only', () {
      final budgets = {
        'a': const MonthlyBudgetEntry(
          targetMinorMain: 100,
          kind: BudgetKind.expense,
        ),
        'b': const MonthlyBudgetEntry(
          targetMinorMain: 50,
          kind: BudgetKind.income,
        ),
      };
      expect(totalIncomeBudgetMinor(budgets), 50);
    });

    test('positiveExpenseMinorFromSignedNet', () {
      expect(positiveExpenseMinorFromSignedNet(-5000), 5000);
      expect(positiveExpenseMinorFromSignedNet(0), 0);
      expect(positiveExpenseMinorFromSignedNet(100), 0);
    });

    test('positiveIncomeMinorFromSignedNet', () {
      expect(positiveIncomeMinorFromSignedNet(10_000), 10_000);
      expect(positiveIncomeMinorFromSignedNet(0), 0);
      expect(positiveIncomeMinorFromSignedNet(-100), 0);
    });

    test('fixedExpensesBudgetAndSpent uses fixed-expenses id', () {
      final m = _month(byCategory: {'fixed-expenses': -12_000});
      final budgets = {
        'fixed-expenses': const MonthlyBudgetEntry(
          targetMinorMain: 30_000,
          kind: BudgetKind.expense,
        ),
      };
      final r = fixedExpensesBudgetAndSpent(m, budgets);
      expect(r.budgetedMinor, 30_000);
      expect(r.spentMinor, 12_000);
    });

    test(
      'incomeCategoryBudgetTargetMinor sums budgets for income categories only',
      () {
        final budgets = {
          'sal': const MonthlyBudgetEntry(
            targetMinorMain: 5000,
            kind: BudgetKind.income,
          ),
          'food': const MonthlyBudgetEntry(
            targetMinorMain: 2000,
            kind: BudgetKind.expense,
          ),
        };
        final cats = [
          FinkoCategory(
            id: 'sal',
            name: 'Salary',
            kind: CategoryKind.income,
            iconKey: 'x',
            sortOrder: 0,
          ),
          FinkoCategory(
            id: 'food',
            name: 'Food',
            kind: CategoryKind.expense,
            iconKey: 'y',
            sortOrder: 1,
          ),
        ];
        expect(incomeCategoryBudgetTargetMinor(budgets, cats), 5000);
      },
    );
  });
}
