import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/firestore_paths.dart';
import '../../../core/data/providers/finko_stream_providers.dart';

const String kProductTourCompletedPrefKey = 'finko_product_tour_completed';

final productTourCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getBool(kProductTourCompletedPrefKey);
  final uid = ref.watch(authUidProvider);
  if (uid == null) {
    return cached ?? false;
  }
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  if (profile != null) {
    // Read from stream when available; field may not be on model yet — check map.
    final completed = await _readCompletedFromFirestore(ref, uid);
    if (completed) {
      await prefs.setBool(kProductTourCompletedPrefKey, true);
      return true;
    }
  }
  if (cached == true) return true;
  return false;
});

Future<bool> _readCompletedFromFirestore(Ref ref, String uid) async {
  try {
    final snap = await ref
        .read(firestoreProvider)
        .doc(FirestorePaths.userDoc(uid))
        .get();
    return snap.data()?['productTourCompleted'] == true;
  } catch (_) {
    return false;
  }
}

Future<void> setProductTourCompleted({
  required FirebaseFirestore firestore,
  required String uid,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kProductTourCompletedPrefKey, true);
  await firestore.doc(FirestorePaths.userDoc(uid)).set({
    'productTourCompleted': true,
  }, SetOptions(merge: true));
}
