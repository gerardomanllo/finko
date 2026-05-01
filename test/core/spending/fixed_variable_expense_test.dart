import 'package:finko/core/spending/fixed_variable_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splitFixedVariableFromPositiveSlices', () {
    test('fixed row follows fixed-expenses slice only; variable is remainder', () {
      const total = 8000;
      final positive = <String, int>{
        kFixedExpensesCategoryId: 0,
        'therapy': 4000,
        'services': 4000,
      };
      final r = splitFixedVariableFromPositiveSlices(
        totalExpenseMinorMain: total,
        positiveExpenseByCategoryMinorMain: positive,
      );
      expect(r.fixedMinorMain, 0);
      expect(r.variableMinorMain, 8000);
    });

    test('fixed slice capped to total; remainder is variable', () {
      const total = 8000;
      final positive = <String, int>{
        kFixedExpensesCategoryId: 2000,
        'food': 6000,
      };
      final r = splitFixedVariableFromPositiveSlices(
        totalExpenseMinorMain: total,
        positiveExpenseByCategoryMinorMain: positive,
      );
      expect(r.fixedMinorMain, 2000);
      expect(r.variableMinorMain, 6000);
    });
  });
}
