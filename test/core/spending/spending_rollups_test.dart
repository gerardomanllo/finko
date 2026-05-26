import 'package:finko/core/data/models/monthly_totals.dart';
import 'package:finko/core/spending/fixed_variable_expense.dart';
import 'package:finko/core/spending/spending_rollups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mergeMonthlyTotals', () {
    test('sums income expense and merges category maps', () {
      final a = MonthlyTotals(
        yearMonth: '2026-01',
        incomeMinorMain: 100,
        expenseMinorMain: 40,
        byCategoryMinorMain: {'c1': -40},
        days: const {},
      );
      final b = MonthlyTotals(
        yearMonth: '2026-02',
        incomeMinorMain: 50,
        expenseMinorMain: 60,
        byCategoryMinorMain: {'c1': -20, 'car': -10},
        days: const {},
      );
      final m = mergeMonthlyTotals([a, b]);
      expect(m.incomeMinorMain, 150);
      expect(m.expenseMinorMain, 100);
      expect(m.byCategoryMinorMain['c1'], -60);
      expect(m.byCategoryMinorMain['car'], -10);
    });
  });

  group('splitFixedVariableExpense', () {
    test('splits from signed fixed-flagged categories', () {
      final r = splitFixedVariableExpense(
        totalExpenseMinorMain: 100,
        byCategoryMinorMain: {'car': -30, 'other': -70},
        fixedCategoryIds: const {'car'},
      );
      expect(r.fixedMinorMain, 30);
      expect(r.variableMinorMain, 70);
    });

    test('caps fixed at total', () {
      final r = splitFixedVariableExpense(
        totalExpenseMinorMain: 50,
        byCategoryMinorMain: {'car': -80},
        fixedCategoryIds: const {'car'},
      );
      expect(r.fixedMinorMain, 50);
      expect(r.variableMinorMain, 0);
    });
  });
}
