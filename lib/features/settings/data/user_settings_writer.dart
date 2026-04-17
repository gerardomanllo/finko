import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/firestore_paths.dart';
import '../../../core/data/models/finko_enums.dart';

final userSettingsWriterProvider = Provider<UserSettingsWriter>((ref) {
  return UserSettingsWriter(firestore: ref.watch(firestoreProvider));
});

/// Small Firestore writes for settings (theme, messaging) — see `docs/settings.md`.
class UserSettingsWriter {
  UserSettingsWriter({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<void> setThemePreference(String uid, ThemePreference pref) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).set({
      'themePreference': pref.wireName,
    }, SetOptions(merge: true));
  }

  /// Removes one messaging integration while preserving the other when present.
  Future<void> clearMessagingIntegration(String uid, String channel) async {
    final docRef = _firestore.doc(FirestorePaths.userDoc(uid));
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final raw = data['integrations'];
    if (raw is! Map) {
      return;
    }
    final map = Map<String, dynamic>.from(raw);
    if (channel == 'whatsapp') {
      map.remove('whatsapp');
    } else {
      map.remove('telegram');
    }
    if (map.isEmpty) {
      await docRef.update({'integrations': FieldValue.delete()});
    } else {
      await docRef.set({'integrations': map}, SetOptions(merge: true));
    }
  }
}
