import 'spending_date_math.dart';
import 'spending_granularity.dart';
import 'spending_period_descriptor.dart';

/// How many period cards to show in the horizontal strip ([`docs/spending.md`]).
const int kSpendingStripCountWeekMonthQuarter = 12;
const int kSpendingStripCountYear = 8;

/// Builds period cards **oldest → newest** (left → right); default selection is last.
List<SpendingPeriodDescriptor> buildSpendingPeriodStrip({
  required SpendingGranularity granularity,
  required String todayYyyyMmDd,
}) {
  final today = parseYyyyMmDd(todayYyyyMmDd);
  return switch (granularity) {
    SpendingGranularity.week => _weeks(today),
    SpendingGranularity.month => _months(today),
    SpendingGranularity.quarter => _quarters(today),
    SpendingGranularity.year => _years(today),
  };
}

List<SpendingPeriodDescriptor> _weeks(DateTime today) {
  final thisMonday = mondayOfWeekContaining(today);
  final out = <SpendingPeriodDescriptor>[];
  for (var i = kSpendingStripCountWeekMonthQuarter - 1; i >= 0; i--) {
    final monday = thisMonday.subtract(Duration(days: 7 * i));
    final sunday = sundayOfWeekStartingMonday(monday);
    final start = formatYyyyMmDd(monday);
    final end = formatYyyyMmDd(sunday);
    out.add(
      SpendingPeriodDescriptor(
        granularity: SpendingGranularity.week,
        startYyyyMmDd: start,
        endYyyyMmDd: end,
        key: 'week:$start',
      ),
    );
  }
  return out;
}

List<SpendingPeriodDescriptor> _months(DateTime today) {
  final out = <SpendingPeriodDescriptor>[];
  for (var k = kSpendingStripCountWeekMonthQuarter - 1; k >= 0; k--) {
    final first = DateTime.utc(today.year, today.month - k, 1);
    final last = lastDayOfMonth(first);
    final start = formatYyyyMmDd(first);
    final end = formatYyyyMmDd(last);
    out.add(
      SpendingPeriodDescriptor(
        granularity: SpendingGranularity.month,
        startYyyyMmDd: start,
        endYyyyMmDd: end,
        key: 'month:${first.year}-${first.month.toString().padLeft(2, '0')}',
      ),
    );
  }
  return out;
}

List<SpendingPeriodDescriptor> _quarters(DateTime today) {
  var y = today.year;
  var q = quarterForMonth(today.month);
  final out = <SpendingPeriodDescriptor>[];
  for (var n = 0; n < kSpendingStripCountWeekMonthQuarter; n++) {
    final first = firstDayOfQuarter(y, q);
    final last = lastDayOfQuarter(y, q);
    out.add(
      SpendingPeriodDescriptor(
        granularity: SpendingGranularity.quarter,
        startYyyyMmDd: formatYyyyMmDd(first),
        endYyyyMmDd: formatYyyyMmDd(last),
        key: 'quarter:$y-$q',
      ),
    );
    q -= 1;
    if (q < 1) {
      q = 4;
      y -= 1;
    }
  }
  out.sort((a, b) => a.startYyyyMmDd.compareTo(b.startYyyyMmDd));
  return out;
}

List<SpendingPeriodDescriptor> _years(DateTime today) {
  final startYear = today.year - (kSpendingStripCountYear - 1);
  final out = <SpendingPeriodDescriptor>[];
  for (var y = startYear; y <= today.year; y++) {
    final first = DateTime.utc(y, 1, 1);
    final last = DateTime.utc(y, 12, 31);
    out.add(
      SpendingPeriodDescriptor(
        granularity: SpendingGranularity.year,
        startYyyyMmDd: formatYyyyMmDd(first),
        endYyyyMmDd: formatYyyyMmDd(last),
        key: 'year:$y',
      ),
    );
  }
  return out;
}
