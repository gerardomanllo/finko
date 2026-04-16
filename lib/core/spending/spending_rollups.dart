import '../data/models/monthly_totals.dart';
import 'spending_date_math.dart';
import 'spending_period_descriptor.dart';

/// Every `yyyy-MM` from [startYyyyMm] through [endYyyyMm] inclusive (lexicographic ok when same year).
List<String> yearMonthsInclusive(String startYyyyMm, String endYyyyMm) {
  var y = int.parse(startYyyyMm.substring(0, 4));
  var m = int.parse(startYyyyMm.substring(5, 7));
  final endY = int.parse(endYyyyMm.substring(0, 4));
  final endM = int.parse(endYyyyMm.substring(5, 7));
  final out = <String>[];
  while (y < endY || (y == endY && m <= endM)) {
    out.add('$y-${m.toString().padLeft(2, '0')}');
    m++;
    if (m > 12) {
      m = 1;
      y++;
    }
  }
  return out;
}

/// Month keys touched by a spending period (one month to twelve).
List<String> yearMonthsForSpendingPeriod(SpendingPeriodDescriptor period) {
  final startYm = period.startYyyyMmDd.substring(0, 7);
  final endYm = period.endYyyyMmDd.substring(0, 7);
  return yearMonthsInclusive(startYm, endYm);
}

/// Merged month-level aggregates for quarter/year / multi-month views.
class MergedMonthlyRollup {
  const MergedMonthlyRollup({
    required this.incomeMinorMain,
    required this.expenseMinorMain,
    required this.byCategoryMinorMain,
  });

  final int incomeMinorMain;
  final int expenseMinorMain;
  final Map<String, int> byCategoryMinorMain;
}

/// Sums non-null [`MonthlyTotals`] docs (main-currency fields).
MergedMonthlyRollup mergeMonthlyTotals(Iterable<MonthlyTotals?> months) {
  var inc = 0;
  var exp = 0;
  final byCat = <String, int>{};
  for (final m in months) {
    if (m == null) continue;
    inc += m.incomeMinorMain;
    exp += m.expenseMinorMain;
    for (final e in m.byCategoryMinorMain.entries) {
      byCat[e.key] = (byCat[e.key] ?? 0) + e.value;
    }
  }
  return MergedMonthlyRollup(
    incomeMinorMain: inc,
    expenseMinorMain: exp,
    byCategoryMinorMain: byCat,
  );
}

/// Income + expense from [`MonthlyTotals.days`] across [startYyyyMmDd]…[endYyyyMmDd] inclusive.
({int incomeMinorMain, int expenseMinorMain}) sumDayIncomeExpenseInRange({
  required String startYyyyMmDd,
  required String endYyyyMmDd,
  required Map<String, MonthlyTotals?> totalsByYearMonth,
}) {
  var inc = 0;
  var exp = 0;
  var cursor = parseYyyyMmDd(startYyyyMmDd);
  final end = parseYyyyMmDd(endYyyyMmDd);
  while (!cursor.isAfter(end)) {
    final ymd = formatYyyyMmDd(cursor);
    final ym = ymd.substring(0, 7);
    final dayKey = ymd.substring(8, 10);
    final monthDoc = totalsByYearMonth[ym];
    final day = monthDoc?.days[dayKey];
    inc += day?.incomeMinorMain ?? 0;
    exp += day?.expenseMinorMain ?? 0;
    cursor = cursor.add(const Duration(days: 1));
  }
  return (incomeMinorMain: inc, expenseMinorMain: exp);
}

/// All `yyyy-MM` keys touched by an inclusive date range (at least one, at most ~length in days for long ranges).
List<String> yearMonthKeysTouchingRange(
  String startYyyyMmDd,
  String endYyyyMmDd,
) {
  final keys = <String>{};
  var cursor = parseYyyyMmDd(startYyyyMmDd);
  final end = parseYyyyMmDd(endYyyyMmDd);
  while (!cursor.isAfter(end)) {
    keys.add(
      '${cursor.year.toString().padLeft(4, '0')}-'
      '${cursor.month.toString().padLeft(2, '0')}',
    );
    cursor = cursor.add(const Duration(days: 1));
  }
  final list = keys.toList()..sort();
  return list;
}
