import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/auth/finko_email_password_form.dart';
import '../../../widgets/auth/finko_social_auth_buttons.dart';
import '../../../widgets/finko_logo.dart';

/// Email/password + Google + Apple ([`docs/login.md`]). WhatsApp/Telegram are not
/// auth providers (see Settings for messaging).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _errorCode;
  String? _infoCode;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _errorCode = null;
      _infoCode = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_register) {
        await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorCode = e.code);
    } catch (_) {
      setState(() => _errorCode = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _errorCode = null;
      _infoCode = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      await auth.signInWithGoogle();
    } on AuthCancelledException {
      // User dismissed picker; not an error.
    } on GoogleIdTokenMissingException {
      setState(() => _errorCode = 'google-config');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorCode = e.code);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Google sign-in PlatformException: ${e.code} ${e.message}');
      }
      setState(() => _errorCode = e.code);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Google sign-in error: $e\n$st');
      }
      setState(() => _errorCode = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apple() async {
    setState(() {
      _busy = true;
      _errorCode = null;
      _infoCode = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      await auth.signInWithApple();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorCode = e.code);
    } catch (_) {
      setState(() => _errorCode = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    setState(() {
      _errorCode = null;
      _infoCode = null;
    });
    if (email.isEmpty) {
      setState(() => _errorCode = 'missing-email');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorCode = 'invalid-email');
      return;
    }
    setState(() => _busy = true);
    final auth = ref.read(authRepositoryProvider);
    try {
      await auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _infoCode = 'password-reset-sent');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorCode = e.code);
    } catch (_) {
      setState(() => _errorCode = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ).copyWith(
                      bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: FinkoLogo()),
                    const SizedBox(height: 20),
                    Text(
                      l10n.loginTitle,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FinkoEmailPasswordForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      emailLabel: l10n.loginEmailLabel,
                      passwordLabel: l10n.loginPasswordLabel,
                      validationRequired: l10n.loginValidationRequired,
                      validationEmail: l10n.loginValidationEmail,
                      validationPasswordLength:
                          l10n.loginValidationPasswordLength,
                      primaryLabel: _register
                          ? l10n.loginCreateAccount
                          : l10n.loginSignIn,
                      toggleLabel: _register
                          ? l10n.loginToggleSignIn
                          : l10n.loginToggleSignUp,
                      forgotPasswordLabel: l10n.loginForgotPassword,
                      onSubmit: _submitEmailPassword,
                      onForgotPassword: _forgotPassword,
                      onToggleMode: () => setState(() {
                        _register = !_register;
                        _errorCode = null;
                        _infoCode = null;
                      }),
                      errorText: _errorCode != null
                          ? _messageForCode(l10n, _errorCode!)
                          : null,
                      infoText: _infoCode != null
                          ? _infoMessageForCode(l10n, _infoCode!)
                          : null,
                      busy: _busy,
                    ),
                    const SizedBox(height: 24),
                    FinkoSocialAuthButtons(
                      onGoogle: _google,
                      onApple: _apple,
                      googleLabel: l10n.loginGoogle,
                      appleLabel: l10n.loginApple,
                      busy: _busy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _messageForCode(AppLocalizations l10n, String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.loginErrorInvalidCredential;
      case 'email-already-in-use':
        return l10n.loginErrorEmailInUse;
      case 'invalid-email':
        return l10n.loginValidationEmail;
      case 'weak-password':
        return l10n.loginValidationPasswordLength;
      case 'missing-email':
        return l10n.loginForgotPasswordMissingEmail;
      case 'google-config':
        return l10n.loginErrorGoogleConfig;
      case 'unknown':
        return l10n.loginErrorGeneric;
      default:
        return l10n.loginErrorGeneric;
    }
  }

  String _infoMessageForCode(AppLocalizations l10n, String code) {
    switch (code) {
      case 'password-reset-sent':
        return l10n.loginForgotPasswordSent;
      default:
        return '';
    }
  }
}
