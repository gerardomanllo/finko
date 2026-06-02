import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

import '../locale/app_environment_provider.dart';
import 'firebase_auth_providers.dart';
import 'google_auth_config.dart';

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  return GoogleSignIn(
    scopes: const <String>['email', 'profile'],
    serverClientId: GoogleAuthConfig.webClientId(env),
    clientId: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? GoogleAuthConfig.iosClientId(env)
        : null,
  );
});

final authRepositoryProvider = Provider<AuthActions>(
  (ref) => AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  ),
);

abstract class AuthActions {
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
}

class AuthRepository implements AuthActions {
  AuthRepository({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  }) : _auth = auth,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Google: web uses Firebase popup; iOS/Android use `google_sign_in` + credential.
  @override
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw AuthCancelledException();
    }
    final ga = await account.authentication;
    final idToken = ga.idToken;
    if (idToken == null) {
      throw GoogleIdTokenMissingException();
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: ga.accessToken,
      idToken: idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Apple: web uses Firebase popup; native uses Sign in with Apple + OAuth credential.
  @override
  Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      final provider = OAuthProvider('apple.com');
      return _auth.signInWithPopup(provider);
    }

    final rawNonce = _generateNonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
    return _auth.signInWithCredential(oauthCredential);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Local Google session cleanup should not block Firebase sign-out.
      }
    }
    await _auth.signOut();
  }
}

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

/// User closed the Google account picker or cancelled the flow.
class AuthCancelledException implements Exception {}

/// Google returned no ID token (usually missing `serverClientId` / OAuth setup).
class GoogleIdTokenMissingException implements Exception {}
