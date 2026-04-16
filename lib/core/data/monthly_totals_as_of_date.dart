import 'models/monthly_totals.dart';

/// Sums [MonthlyTotals.days] expense fields for calendar days `01`…`today` (inclusive)
/// when [totals.yearMonth] matches the month of [throughYyyyMmDd].
///
/// Otherwise returns [MonthlyTotals.expenseMinorMain] (caller should align month doc
/// with [throughYyyyMmDd]).
int expenseMinorMainThroughDate(MonthlyTotals totals, String throughYyyyMmDd) {
  if (totals.yearMonth.length < 7 || throughYyyyMmDd.length < 10) {
    return totals.expenseMinorMain;
  }
  final monthPrefix = throughYyyyMmDd.substring(0, 7);
  if (totals.yearMonth != monthPrefix) {
    return totals.expenseMinorMain;
  }
  final dayCap = int.tryParse(throughYyyyMmDd.substring(8, 10)) ?? 31;
  var sum = 0;
  for (final e in totals.days.entries) {
    final dk = e.key;
    if (!_isDayKey(dk)) continue;
    final d = int.parse(dk);
    if (d > dayCap) continue;
    sum += e.value.expenseMinorMain ?? 0;
  }
  return sum;
}

/// Scales [MonthlyTotals.byCategoryMinorMain] by the ratio of MTD expense to full-month
/// expense so category rings match **through [throughYyyyMmDd]** when day-level category
/// rollups are absent.
Map<String, int> byCategoryMinorMainThroughDate(
  MonthlyTotals totals,
  String throughYyyyMmDd,
) {
  final monthExp = totals.expenseMinorMain;
  final mtd = expenseMinorMainThroughDate(totals, throughYyyyMmDd);
  if (monthExp <= 0) {
    return {};
  }
  if (mtd <= 0) {
    return {for (final e in totals.byCategoryMinorMain.entries) e.key: 0};
  }
  final ratio = mtd / monthExp;
  return {
    for (final e in totals.byCategoryMinorMain.entries)
      e.key: (e.value * ratio).round(),
  };
}

bool _isDayKey(String k) => RegExp(r'^\d{2}$').hasMatch(k);
