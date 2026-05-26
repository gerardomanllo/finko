import 'package:finko/core/spending/fixed_variable_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splitFixedVariableFromPositiveSlices', () {
    test('sums fixed-flagged slices; variable is remainder', () {
      const total = 8000;
      const fixedIds = {'car'};
      final positive = <String, int>{'car': 2000, 'food': 6000};
      final r = splitFixedVariableFromPositiveSlices(
        totalExpenseMinorMain: total,
        positiveExpenseByCategoryMinorMain: positive,
        fixedCategoryIds: fixedIds,
      );
      expect(r.fixedMinorMain, 2000);
      expect(r.variableMinorMain, 6000);
    });

    test('multiple fixed categories sum into fixed row', () {
      const total = 5000;
      const fixedIds = {'car', 'rent'};
      final positive = <String, int>{'car': 3000, 'rent': 2000};
      final r = splitFixedVariableFromPositiveSlices(
        totalExpenseMinorMain: total,
        positiveExpenseByCategoryMinorMain: positive,
        fixedCategoryIds: fixedIds,
      );
      expect(r.fixedMinorMain, 5000);
      expect(r.variableMinorMain, 0);
    });

    test('no fixed categories → all variable', () {
      const total = 8000;
      final positive = <String, int>{'food': 8000};
      final r = splitFixedVariableFromPositiveSlices(
        totalExpenseMinorMain: total,
        positiveExpenseByCategoryMinorMain: positive,
        fixedCategoryIds: const {},
      );
      expect(r.fixedMinorMain, 0);
      expect(r.variableMinorMain, 8000);
    });

    test('fixed slice sum capped to total expense', () {
      const total = 3000;
      const fixedIds = {'car', 'rent'};
      final positive = <String, int>{'car': 3000, 'rent': 2000, 'food': 1000};
      final r = splitFixedVariableFromPositiveSlices(
        totalExpenseMinorMain: total,
        positiveExpenseByCategoryMinorMain: positive,
        fixedCategoryIds: fixedIds,
      );
      expect(r.fixedMinorMain, 3000);
      expect(r.variableMinorMain, 0);
    });

    test('flagged category with zero spend contributes nothing', () {
      const total = 4000;
      const fixedIds = {'rent'};
      final positive = <String, int>{'rent': 0, 'food': 4000};
      final r = splitFixedVariableFromPositiveSlices(
        totalExpenseMinorMain: total,
        positiveExpenseByCategoryMinorMain: positive,
        fixedCategoryIds: fixedIds,
      );
      expect(r.fixedMinorMain, 0);
      expect(r.variableMinorMain, 4000);
    });
  });

  group('splitFixedVariableExpense (signed byCategory)', () {
    test('sums signed nets for fixed ids', () {
      const total = 8000;
      const fixedIds = {'car'};
      final byCategory = <String, int>{'car': -2000, 'food': -6000};
      final r = splitFixedVariableExpense(
        totalExpenseMinorMain: total,
        byCategoryMinorMain: byCategory,
        fixedCategoryIds: fixedIds,
      );
      expect(r.fixedMinorMain, 2000);
      expect(r.variableMinorMain, 6000);
    });
  });
}
