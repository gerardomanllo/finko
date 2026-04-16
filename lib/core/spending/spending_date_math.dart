/// Calendar helpers for spending periods (local calendar math on `yyyy-MM-dd`).
library;

/// Parses `"yyyy-MM-dd"` to UTC-normalized date-only (no TZ shift for bucketing).
DateTime parseYyyyMmDd(String ymd) {
  final parts = ymd.split('-');
  if (parts.length != 3) {
    throw FormatException('Expected yyyy-MM-dd, got: $ymd');
  }
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);
  return DateTime.utc(y, m, d);
}

String formatYyyyMmDd(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Monday of the ISO week containing [day] (using `DateTime.weekday`: Mon=1).
DateTime mondayOfWeekContaining(DateTime day) {
  final d = DateTime.utc(day.year, day.month, day.day);
  final weekday = d.weekday; // Mon=1 … Sun=7
  return d.subtract(Duration(days: weekday - 1));
}

/// Sunday following the week that starts on [monday] (Monday … Sunday inclusive).
DateTime sundayOfWeekStartingMonday(DateTime monday) {
  final m = DateTime.utc(monday.year, monday.month, monday.day);
  return m.add(const Duration(days: 6));
}

/// Last calendar day of the month containing [anyDayInMonth].
DateTime lastDayOfMonth(DateTime anyDayInMonth) {
  final y = anyDayInMonth.year;
  final m = anyDayInMonth.month;
  return DateTime.utc(y, m + 1, 0);
}

/// First day of quarter `1..4` in [year].
DateTime firstDayOfQuarter(int year, int quarter) {
  final m = (quarter - 1) * 3 + 1;
  return DateTime.utc(year, m, 1);
}

/// Last day of quarter `1..4` in [year].
DateTime lastDayOfQuarter(int year, int quarter) {
  final m = quarter * 3;
  return DateTime.utc(year, m + 1, 0);
}

/// Quarter `1..4` for the calendar month `1..12`.
int quarterForMonth(int month) => (month - 1) ~/ 3 + 1;
