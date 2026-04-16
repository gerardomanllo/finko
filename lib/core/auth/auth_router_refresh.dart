import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_auth_providers.dart';

/// Notifies [GoRouter] when [FirebaseAuth.authStateChanges] emits so redirects
/// re-run (login ↔ app shell).
final authRouterRefreshProvider = Provider<AuthRouterRefresh>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final notifier = AuthRouterRefresh(auth);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(this._auth) {
    _subscription = _auth.authStateChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
