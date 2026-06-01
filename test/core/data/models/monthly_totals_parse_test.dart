import 'package:finko/core/data/models/monthly_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MonthlyTotals.fromJson treats null income/expense as zero', () {
    final m = MonthlyTotals.fromJson(<String, dynamic>{
      'yearMonth': '2026-05',
      'byCategoryMinorMain': <String, dynamic>{},
      'days': <String, dynamic>{},
    });
    expect(m.incomeMinorMain, 0);
    expect(m.expenseMinorMain, 0);
  });
}
