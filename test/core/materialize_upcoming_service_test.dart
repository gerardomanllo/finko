import 'package:finko/core/upcoming/materialize_upcoming_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('runs callable once per day per user', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final payloads = <Map<String, dynamic>>[];
    final service = MaterializeUpcomingService(
      callable: (payload) async => payloads.add(payload),
      now: () => DateTime(2026, 4, 16, 8),
    );

    await service.runOncePerDayIfSignedIn('uid-1');
    await service.runOncePerDayIfSignedIn('uid-1');

    expect(payloads.length, 1);
    expect(payloads.single['uid'], 'uid-1');
    expect(payloads.single['asOfDate'], '2026-04-16');
  });

  test('sends timezone and omits asOfDate when timezone is present', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final payloads = <Map<String, dynamic>>[];
    final service = MaterializeUpcomingService(
      callable: (payload) async => payloads.add(payload),
      now: () => DateTime(2026, 4, 16, 8),
    );

    await service.runOncePerDayIfSignedIn(
      'uid-2',
      timezone: 'America/Mexico_City',
    );

    expect(payloads.length, 1);
    expect(payloads.single['uid'], 'uid-2');
    expect(payloads.single['timezone'], 'America/Mexico_City');
    expect(payloads.single.containsKey('asOfDate'), isFalse);
  });

  test('force refresh bypasses once-per-day guard', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final payloads = <Map<String, dynamic>>[];
    final service = MaterializeUpcomingService(
      callable: (payload) async => payloads.add(payload),
      now: () => DateTime(2026, 4, 16, 8),
    );

    await service.runOncePerDayIfSignedIn('uid-3');
    await service.forceRefreshIfSignedIn('uid-3');

    expect(payloads.length, 2);
  });
}
