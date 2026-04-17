/// Inclusive calendar days from [today] through the last day of [viewedMonth],
/// when [today] falls inside that month. If [today] is before the month starts
/// (viewing a future month), returns the full month length. If [today] is after
/// the month ends (past month), returns `0`.
///
/// [viewedMonth] should be `DateTime(year, month, 1)`.
///
/// Spending pace ([`docs/budgets.md`]) uses this count with **left to spend** =
/// total expense budget (profile **`budgets`** map) minus **`MonthlyTotals`**
/// `expenseMinorMain`, same as the card’s “Left for spending” figure.
int calendarDaysRemainingInViewedMonth(DateTime viewedMonth, DateTime today) {
  final first = DateTime(viewedMonth.year, viewedMonth.month, 1);
  final lastDay = DateTime(viewedMonth.year, viewedMonth.month + 1, 0).day;
  final last = DateTime(viewedMonth.year, viewedMonth.month, lastDay);
  final t = DateTime(today.year, today.month, today.day);
  if (t.isAfter(last)) {
    return 0;
  }
  if (t.isBefore(first)) {
    return last.difference(first).inDays + 1;
  }
  return last.difference(t).inDays + 1;
}

/// Average minor units per remaining day: `round(leftMinor / daysRemaining)`.
/// Returns `0` if [daysRemaining] is `0`.
int paceMinorPerDay({required int leftMinor, required int daysRemaining}) {
  if (daysRemaining <= 0) {
    return 0;
  }
  return (leftMinor / daysRemaining).round();
}
