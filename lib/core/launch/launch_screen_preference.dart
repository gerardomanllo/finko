import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/firebase_auth_providers.dart';
import '../data/firestore_paths.dart';

const String kLaunchScreenPrefKey = 'finko_launch_screen';
const String kAgentHomePromptSeenKey = 'finko_agent_home_prompt_seen';

enum LaunchScreen { dashboard, agent }

LaunchScreen launchScreenFromWire(String? wire) {
  if (wire == 'agent') return LaunchScreen.agent;
  return LaunchScreen.dashboard;
}

String launchScreenToWire(LaunchScreen screen) {
  return screen == LaunchScreen.agent ? 'agent' : 'dashboard';
}

final launchScreenPreferenceProvider = FutureProvider<LaunchScreen>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(kLaunchScreenPrefKey);
  final uid = ref.watch(authUidProvider);
  if (uid == null) {
    return launchScreenFromWire(cached);
  }
  try {
    final snap = await ref
        .watch(firestoreProvider)
        .doc(FirestorePaths.userDoc(uid))
        .get();
    final wire = snap.data()?['launchScreen'] as String?;
    if (wire != null) {
      await prefs.setString(kLaunchScreenPrefKey, wire);
      return launchScreenFromWire(wire);
    }
  } catch (_) {
    // Offline — use cache.
  }
  return launchScreenFromWire(cached);
});

Future<void> setLaunchScreenPreference({
  required FirebaseFirestore firestore,
  required String uid,
  required LaunchScreen screen,
}) async {
  final wire = launchScreenToWire(screen);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kLaunchScreenPrefKey, wire);
  await firestore.doc(FirestorePaths.userDoc(uid)).set({
    'launchScreen': wire,
  }, SetOptions(merge: true));
}

Future<bool> readAgentHomePromptSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kAgentHomePromptSeenKey) ?? false;
}

Future<void> markAgentHomePromptSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kAgentHomePromptSeenKey, true);
}
