import 'package:finko/core/data/models/monthly_totals.dart';
import 'package:finko/core/data/monthly_totals_as_of_date.dart';
import 'package:flutter_test/flutter_test.dart';

MonthlyTotals _totals({
  required String yearMonth,
  required int expenseMinorMain,
  Map<String, int> byCategory = const {},
  Map<String, MonthlyDayRollup> days = const {},
}) {
  return MonthlyTotals(
    yearMonth: yearMonth,
    incomeMinorMain: 0,
    expenseMinorMain: expenseMinorMain,
    byCategoryMinorMain: byCategory,
    days: days,
  );
}

void main() {
  group('expenseMinorMainThroughDate', () {
    test('sums day expenses for days 01 through cap inclusive', () {
      final m = _totals(
        yearMonth: '2026-04',
        expenseMinorMain: 999,
        days: {
          '05': const MonthlyDayRollup(expenseMinorMain: 100),
          '10': const MonthlyDayRollup(expenseMinorMain: 200),
          '20': const MonthlyDayRollup(expenseMinorMain: 400),
        },
      );
      expect(expenseMinorMainThroughDate(m, '2026-04-15'), 300);
    });

    test(
      'returns full month expense when totals month differs from through date',
      () {
        final m = _totals(yearMonth: '2026-03', expenseMinorMain: 5000);
        expect(expenseMinorMainThroughDate(m, '2026-04-10'), 5000);
      },
    );
  });

  group('byCategoryMinorMainThroughDate', () {
    test('scales category map by MTD over full-month expense ratio', () {
      final m = _totals(
        yearMonth: '2026-04',
        expenseMinorMain: 1000,
        byCategory: {'c1': 600, 'c2': 400},
        days: {'10': const MonthlyDayRollup(expenseMinorMain: 500)},
      );
      // MTD through 2026-04-10 = 500; ratio 0.5
      final out = byCategoryMinorMainThroughDate(m, '2026-04-10');
      expect(out['c1'], 300);
      expect(out['c2'], 200);
    });
  });
}
