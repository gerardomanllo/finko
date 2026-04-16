import 'package:finko/core/spending/spending_granularity.dart';
import 'package:finko/core/spending/spending_period_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildSpendingPeriodStrip', () {
    test('months are ascending and last is current month', () {
      final strip = buildSpendingPeriodStrip(
        granularity: SpendingGranularity.month,
        todayYyyyMmDd: '2026-03-15',
      );
      expect(strip.length, kSpendingStripCountWeekMonthQuarter);
      for (var i = 1; i < strip.length; i++) {
        expect(
          strip[i - 1].startYyyyMmDd.compareTo(strip[i].startYyyyMmDd),
          lessThan(0),
        );
      }
      expect(strip.last.startYyyyMmDd, '2026-03-01');
      expect(strip.last.endYyyyMmDd, '2026-03-31');
    });

    test('weeks are ascending and last ends on Sunday of current week', () {
      final strip = buildSpendingPeriodStrip(
        granularity: SpendingGranularity.week,
        todayYyyyMmDd: '2026-03-18', // Wednesday
      );
      expect(strip.length, kSpendingStripCountWeekMonthQuarter);
      for (var i = 1; i < strip.length; i++) {
        expect(
          strip[i - 1].startYyyyMmDd.compareTo(strip[i].startYyyyMmDd),
          lessThan(0),
        );
      }
      expect(strip.last.startYyyyMmDd, '2026-03-16'); // Monday
      expect(strip.last.endYyyyMmDd, '2026-03-22'); // Sunday
    });

    test('years are ascending ending in current year', () {
      final strip = buildSpendingPeriodStrip(
        granularity: SpendingGranularity.year,
        todayYyyyMmDd: '2026-06-01',
      );
      expect(strip.length, kSpendingStripCountYear);
      expect(strip.first.startYyyyMmDd, '2019-01-01');
      expect(strip.last.endYyyyMmDd, '2026-12-31');
    });
  });
}
