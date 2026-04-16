import 'package:finko/core/datetime/user_calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('daysBetweenYyyyMmDd counts calendar days', () {
    expect(daysBetweenYyyyMmDd('2026-04-10', '2026-04-10'), 0);
    expect(daysBetweenYyyyMmDd('2026-04-10', '2026-04-17'), 7);
    expect(daysBetweenYyyyMmDd('2026-04-10', '2026-04-18'), 8);
  });

  test('userCalendarDateYyyyMmDd uses IANA zone when set', () {
    final ymd = userCalendarDateYyyyMmDd(
      utcNow: DateTime.utc(2026, 4, 16, 8, 0),
      ianaTimezone: 'America/Mexico_City',
    );
    expect(ymd, '2026-04-16');
  });
}
