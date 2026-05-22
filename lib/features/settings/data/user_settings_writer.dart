import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/firestore_paths.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/agent_preferences.dart';

final userSettingsWriterProvider = Provider<UserSettingsWriter>((ref) {
  return UserSettingsWriter(firestore: ref.watch(firestoreProvider));
});

/// Firestore writes for settings (theme, Telegram bot defaults) — see `docs/settings.md`.
class UserSettingsWriter {
  UserSettingsWriter({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<void> setThemePreference(String uid, ThemePreference pref) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).set({
      'themePreference': pref.wireName,
    }, SetOptions(merge: true));
  }

  Future<void> setAgentPreferences(String uid, AgentPreferences prefs) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).set(
      {'agentPreferences': prefs.toJson()},
      SetOptions(merge: true),
    );
  }

  Future<void> clearAgentPreferences(String uid) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).set(
      {'agentPreferences': <String, dynamic>{}},
      SetOptions(merge: true),
    );
  }

  @Deprecated('Use setAgentPreferences')
  Future<void> setTelegramBotPreferences(String uid, AgentPreferences prefs) =>
      setAgentPreferences(uid, prefs);

  @Deprecated('Use clearAgentPreferences')
  Future<void> clearTelegramBotPreferences(String uid) =>
      clearAgentPreferences(uid);
}
