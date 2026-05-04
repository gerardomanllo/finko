import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/firestore_paths.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/telegram_bot_preferences.dart';

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

  Future<void> setTelegramBotPreferences(
    String uid,
    TelegramBotPreferences prefs,
  ) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).set(
      {'telegramBotPreferences': prefs.toJson()},
      SetOptions(merge: true),
    );
  }

  Future<void> clearTelegramBotPreferences(String uid) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).set(
      {'telegramBotPreferences': <String, dynamic>{}},
      SetOptions(merge: true),
    );
  }
}
