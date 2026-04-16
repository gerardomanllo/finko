import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLastMaterializeDateKey = 'finko_last_materialize_yyyy_mm_dd';

/// Invokes `materializeDueUpcoming` at most once per calendar day per device.
class MaterializeUpcomingService {
  MaterializeUpcomingService({required FirebaseFunctions functions})
    : _functions = functions;

  final FirebaseFunctions _functions;

  Future<void> runOncePerDayIfSignedIn(String uid) async {
    final today = _todayLocalYmd();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kLastMaterializeDateKey) == today) return;

    final callable = _functions.httpsCallable('materializeDueUpcoming');
    try {
      await callable.call(<String, dynamic>{'uid': uid, 'asOfDate': today});
      await prefs.setString(_kLastMaterializeDateKey, today);
    } catch (e, st) {
      debugPrint('materializeDueUpcoming failed: $e\n$st');
    }
  }

  static String _todayLocalYmd() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }
}
