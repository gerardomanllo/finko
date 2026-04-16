import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLastReconcileDateKeyPrefix = 'finko_last_deferred_ledger_reconcile_yyyy_mm_dd';

typedef DeferredLedgerCallable = Future<void> Function(Map<String, dynamic> payload);
typedef PreferencesLoader = Future<SharedPreferences> Function();

/// Invokes `reconcileDeferredLedgerForUser` — at most once per profile calendar day
/// for [runOncePerProfileDayIfSignedIn], or on demand for [forceReconcileIfSignedIn].
class DeferredLedgerReconcileService {
  DeferredLedgerReconcileService({
    FirebaseFunctions? functions,
    DeferredLedgerCallable? callable,
    PreferencesLoader? preferencesLoader,
  }) : assert(
         callable != null || functions != null,
         'Provide either functions or callable.',
       ),
       _callable =
           callable ??
           ((payload) async {
             final httpsCallable = functions!.httpsCallable(
               'reconcileDeferredLedgerForUser',
             );
             await httpsCallable.call(payload);
           }),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final DeferredLedgerCallable _callable;
  final PreferencesLoader _preferencesLoader;

  /// Skips if SharedPreferences already stores [profileTodayYyyyMmDd] for this [uid]
  /// (matches [`todayYyyyMmDdProvider`] — profile timezone when set).
  Future<void> runOncePerProfileDayIfSignedIn(
    String uid,
    String profileTodayYyyyMmDd,
  ) async {
    final prefs = await _preferencesLoader();
    final key = '$_kLastReconcileDateKeyPrefix:$uid';
    if (prefs.getString(key) == profileTodayYyyyMmDd) return;

    try {
      await _callable(<String, dynamic>{'uid': uid});
      await prefs.setString(key, profileTodayYyyyMmDd);
    } catch (e, st) {
      debugPrint('reconcileDeferredLedgerForUser failed: $e\n$st');
    }
  }

  /// Pull-to-refresh / explicit refresh: always calls the callable; updates the
  /// once-per-day key on success so a follow-up lifecycle tick does not double-call.
  Future<void> forceReconcileIfSignedIn(
    String uid,
    String profileTodayYyyyMmDd,
  ) async {
    try {
      await _callable(<String, dynamic>{'uid': uid});
      final prefs = await _preferencesLoader();
      await prefs.setString('$_kLastReconcileDateKeyPrefix:$uid', profileTodayYyyyMmDd);
    } catch (e, st) {
      debugPrint('force reconcileDeferredLedgerForUser failed: $e\n$st');
    }
  }
}
