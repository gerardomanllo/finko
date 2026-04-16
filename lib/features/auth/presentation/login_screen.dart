import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
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
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      await auth.signInWithGoogle();
    } on AuthCancelledException {
      // User dismissed picker; not an error.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorCode = e.code);
    } catch (_) {
      setState(() => _errorCode = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apple() async {
    setState(() {
      _busy = true;
      _errorCode = null;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
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
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n.loginEmailLabel,
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return l10n.loginValidationRequired;
                          if (!s.contains('@')) {
                            return l10n.loginValidationEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: l10n.loginPasswordLabel,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.loginValidationRequired;
                          }
                          if (v.length < 6) {
                            return l10n.loginValidationPasswordLength;
                          }
                          return null;
                        },
                      ),
                      if (_errorCode != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _messageForCode(l10n, _errorCode!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _submitEmailPassword,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _register
                                    ? l10n.loginCreateAccount
                                    : l10n.loginSignIn,
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _register = !_register;
                                _errorCode = null;
                              }),
                        child: Text(
                          _register
                              ? l10n.loginToggleSignIn
                              : l10n.loginToggleSignUp,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _busy ? null : _google,
                        child: Text(l10n.loginGoogle),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _apple,
                        icon: const Icon(Icons.apple, size: 22),
                        label: Text(l10n.loginApple),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.loginMessagingNote,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
      case 'unknown':
        return l10n.loginErrorGeneric;
      default:
        return l10n.loginErrorGeneric;
    }
  }
}
