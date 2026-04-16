import 'package:finko/core/auth/auth_repository.dart';
import 'package:finko/features/auth/presentation/login_screen.dart';
import 'package:finko/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthActions implements AuthActions {
  String? passwordResetEmail;
  FirebaseAuthException? resetError;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithApple() async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (resetError != null) throw resetError!;
    passwordResetEmail = email;
  }
}

Widget _testApp(FakeAuthActions fake) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('login screen shows all auth affordances', (tester) async {
    final fake = FakeAuthActions();
    await tester.pumpWidget(_testApp(fake));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsAtLeastNWidgets(1));
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('forgot password requires email', (tester) async {
    final fake = FakeAuthActions();
    await tester.pumpWidget(_testApp(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter your email above to reset your password'),
      findsOneWidget,
    );
  });

  testWidgets('forgot password sends reset email and shows confirmation', (
    tester,
  ) async {
    final fake = FakeAuthActions();
    await tester.pumpWidget(_testApp(fake));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'person@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(fake.passwordResetEmail, 'person@example.com');
    expect(
      find.text('Password reset email sent. Check your inbox.'),
      findsOneWidget,
    );
  });
}
