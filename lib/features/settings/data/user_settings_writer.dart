import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/firestore_paths.dart';
import '../../../core/data/models/finko_enums.dart';

final userSettingsWriterProvider = Provider<UserSettingsWriter>((ref) {
  return UserSettingsWriter(firestore: ref.watch(firestoreProvider));
});

/// Small Firestore writes for settings (theme) — see `docs/settings.md`.
class UserSettingsWriter {
  UserSettingsWriter({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<void> setThemePreference(String uid, ThemePreference pref) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).set({
      'themePreference': pref.wireName,
    }, SetOptions(merge: true));
  }
}
