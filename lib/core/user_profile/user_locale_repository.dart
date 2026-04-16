import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../locale/locale_support.dart';

const _kLocalePrefsKey = 'finko_user_locale_bcp47';

/// Loads and persists app locale: device prefs plus `users/{uid}.locale` when
/// signed in (see docs/data-model.md §3).
abstract class UserLocaleRepository {
  Future<Locale> loadEffectiveLocale();

  /// Writes prefs and, when authenticated, merges `locale` (+ `updatedAt`) on
  /// `users/{uid}`.
  Future<void> persistLocale(Locale locale);

  /// Updates prefs only (e.g. when another device changed Firestore).
  Future<void> cacheLocaleLocally(Locale locale);

  /// Emits when the signed-in user's `locale` field changes remotely.
  Stream<Locale?> get remoteLocaleUpdates;
}

final userLocaleRepositoryProvider = Provider<UserLocaleRepository>((ref) {
  return FirebaseUserLocaleRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class FirebaseUserLocaleRepository implements UserLocaleRepository {
  FirebaseUserLocaleRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<Locale> loadEffectiveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localRaw = prefs.getString(_kLocalePrefsKey);
    final user = _auth.currentUser;
    if (user == null) {
      return localRaw != null && localRaw.isNotEmpty
          ? localeFromBcp47(localRaw)
          : kDefaultAppLocale;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final remoteRaw = doc.data()?['locale'] as String?;
    if (remoteRaw != null && remoteRaw.isNotEmpty) {
      if (remoteRaw != localRaw) {
        await prefs.setString(_kLocalePrefsKey, remoteRaw);
      }
      return localeFromBcp47(remoteRaw);
    }
    if (localRaw != null && localRaw.isNotEmpty) {
      return localeFromBcp47(localRaw);
    }
    return kDefaultAppLocale;
  }

  @override
  Future<void> persistLocale(Locale locale) async {
    final normalized = normalizeAppLocale(locale);
    final tag = localeToBcp47(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalePrefsKey, tag);

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'locale': tag,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> cacheLocaleLocally(Locale locale) async {
    final normalized = normalizeAppLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalePrefsKey, localeToBcp47(normalized));
  }

  @override
  Stream<Locale?> get remoteLocaleUpdates {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return const Stream<Locale?>.empty();
      }
      return _firestore.collection('users').doc(user.uid).snapshots().map((
        snap,
      ) {
        final raw = snap.data()?['locale'] as String?;
        if (raw == null || raw.isEmpty) return null;
        return localeFromBcp47(raw);
      });
    });
  }
}
