import 'package:finko/core/budget/spending_pace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calendarDaysRemainingInViewedMonth', () {
    test('full month when today is before viewed month', () {
      final viewed = DateTime(2026, 3, 1);
      final today = DateTime(2026, 2, 15);
      expect(calendarDaysRemainingInViewedMonth(viewed, today), 31);
    });

    test('inclusive days from today through month end', () {
      final viewed = DateTime(2026, 4, 1);
      final today = DateTime(2026, 4, 14);
      expect(calendarDaysRemainingInViewedMonth(viewed, today), 17);
    });

    test('0 when month is entirely in the past', () {
      final viewed = DateTime(2025, 1, 1);
      final today = DateTime(2026, 4, 15);
      expect(calendarDaysRemainingInViewedMonth(viewed, today), 0);
    });
  });

  group('paceMinorPerDay', () {
    test('divides and rounds', () {
      expect(paceMinorPerDay(leftMinor: 10000, daysRemaining: 3), 3333);
    });

    test('returns 0 when no days', () {
      expect(paceMinorPerDay(leftMinor: 10000, daysRemaining: 0), 0);
    });
  });
}
