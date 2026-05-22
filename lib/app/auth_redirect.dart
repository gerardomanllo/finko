import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/firebase_auth_providers.dart';
import '../core/launch/launch_screen_preference.dart';

/// Resolves the first screen after bootstrap: `/login`, `/onboarding`, or
/// `/dashboard`. Shared by [appAuthRedirect] and the splash screen.
Future<String> resolvePostSplashLocation({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
}) async {
  final User? user = auth.currentUser;
  if (user == null) return '/login';
  final bool onboardingDone = await _readOnboardingCompleted(
    firestore,
    user.uid,
  );
  if (!onboardingDone) return '/onboarding';
  final launch = await _readLaunchScreen(firestore, user.uid);
  return launch == LaunchScreen.agent ? '/agent' : '/dashboard';
}

Future<LaunchScreen> _readLaunchScreen(FirebaseFirestore firestore, String uid) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(kLaunchScreenPrefKey);
    final doc = await firestore.collection('users').doc(uid).get();
    final wire = doc.data()?['launchScreen'] as String? ?? cached;
    if (wire != null) {
      await prefs.setString(kLaunchScreenPrefKey, wire);
    }
    return launchScreenFromWire(wire);
  } catch (_) {
    return LaunchScreen.dashboard;
  }
}

/// Auth + onboarding gate (see docs/onboarding.md). Uses [FirebaseAuth] /
/// [FirebaseFirestore] from [ProviderScope] when [context] is under [FinkoApp].
///
/// If reading `users/{uid}` fails (e.g. [FirebaseException] `permission-denied`
/// before rules are deployed), we treat onboarding as **not** complete so the
/// user is sent to `/onboarding` instead of crashing.
Future<String?> appAuthRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final String location = state.matchedLocation;

  if (location == '/splash') return null;

  final FirebaseAuth auth = container.read(firebaseAuthProvider);
  final FirebaseFirestore firestore = container.read(firestoreProvider);

  final String target = await resolvePostSplashLocation(
    auth: auth,
    firestore: firestore,
  );

  if (target == '/login') {
    if (location == '/login') return null;
    return '/login';
  }
  if (target == '/onboarding') {
    if (location == '/onboarding') return null;
    return '/onboarding';
  }
  if (location == '/login' || location == '/onboarding') {
    return target;
  }
  return null;
}

Future<bool> _readOnboardingCompleted(
  FirebaseFirestore firestore,
  String uid,
) async {
  try {
    final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['onboardingCompleted'] == true;
  } on FirebaseException catch (e) {
    // Common before rules deploy: permission-denied. Treat as onboarding incomplete.
    if (e.code == 'permission-denied' || e.code == 'unavailable') {
      return false;
    }
    rethrow;
  } catch (_) {
    // Offline or transient errors: do not crash the router.
    return false;
  }
}
