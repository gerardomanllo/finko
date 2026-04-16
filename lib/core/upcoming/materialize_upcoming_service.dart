import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLastMaterializeDateKeyPrefix = 'finko_last_materialize_yyyy_mm_dd';
typedef MaterializeCallable =
    Future<void> Function(Map<String, dynamic> payload);
typedef PreferencesLoader = Future<SharedPreferences> Function();

/// Invokes `materializeDueUpcoming` at most once per calendar day per device.
class MaterializeUpcomingService {
  MaterializeUpcomingService({
    FirebaseFunctions? functions,
    MaterializeCallable? callable,
    PreferencesLoader? preferencesLoader,
    DateTime Function()? now,
  }) : assert(
         callable != null || functions != null,
         'Provide either functions or callable.',
       ),
       _callable =
           callable ??
           ((payload) async {
             final httpsCallable = functions!.httpsCallable(
               'materializeDueUpcoming',
             );
             await httpsCallable.call(payload);
           }),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now;

  final MaterializeCallable _callable;
  final PreferencesLoader _preferencesLoader;
  final DateTime Function() _now;

  Future<void> runOncePerDayIfSignedIn(String uid, {String? timezone}) async {
    final today = _todayLocalYmd(_now());
    final prefs = await _preferencesLoader();
    final key = '$_kLastMaterializeDateKeyPrefix:$uid';
    if (prefs.getString(key) == today) return;

    final trimmedTimezone = timezone?.trim();
    final payload = <String, dynamic>{'uid': uid};
    if (trimmedTimezone != null && trimmedTimezone.isNotEmpty) {
      payload['timezone'] = trimmedTimezone;
    } else {
      payload['asOfDate'] = today;
    }
    try {
      await _callable(payload);
      await prefs.setString(key, today);
    } catch (e, st) {
      debugPrint('materializeDueUpcoming failed: $e\n$st');
    }
  }

  /// Manual refresh path (e.g. pull-to-refresh): always invokes callable.
  Future<void> forceRefreshIfSignedIn(String uid, {String? timezone}) async {
    final today = _todayLocalYmd(_now());
    final trimmedTimezone = timezone?.trim();
    final payload = <String, dynamic>{'uid': uid};
    if (trimmedTimezone != null && trimmedTimezone.isNotEmpty) {
      payload['timezone'] = trimmedTimezone;
    } else {
      payload['asOfDate'] = today;
    }
    try {
      await _callable(payload);
    } catch (e, st) {
      debugPrint('manual materializeDueUpcoming failed: $e\n$st');
    }
  }

  static String _todayLocalYmd(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
