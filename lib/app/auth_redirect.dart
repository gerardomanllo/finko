import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/firebase_auth_providers.dart';

/// Auth + onboarding gate (see docs/onboarding.md). Uses [FirebaseAuth] /
/// [FirebaseFirestore] from [ProviderScope] when [context] is under [FinkoApp].
Future<String?> appAuthRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final FirebaseAuth auth = container.read(firebaseAuthProvider);
  final FirebaseFirestore firestore = container.read(firestoreProvider);

  final User? user = auth.currentUser;
  final String location = state.matchedLocation;

  if (user == null) {
    if (location == '/login') return null;
    return '/login';
  }

  final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
      .collection('users')
      .doc(user.uid)
      .get();
  final bool onboardingDone = doc.data()?['onboardingCompleted'] == true;

  if (!onboardingDone) {
    if (location == '/onboarding') return null;
    return '/onboarding';
  }

  if (location == '/login' || location == '/onboarding') {
    return '/dashboard';
  }

  return null;
}
