import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/auth_redirect.dart';
import '../../../core/auth/firebase_auth_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/finko_logo.dart';

/// Minimum time the splash stays visible (cold start branding).
const Duration kMinSplashDuration = Duration(milliseconds: 600);

/// Full-screen splash ([`docs/splash.md`]); navigates when auth gate resolves.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firestoreProvider);

    late final String target;
    try {
      final results = await Future.wait<dynamic>([
        Future<dynamic>.delayed(kMinSplashDuration),
        resolvePostSplashLocation(auth: auth, firestore: firestore),
      ]);
      target = results[1] as String;
    } catch (_) {
      target = '/login';
    }

    if (!mounted) return;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FinkoLogo(size: 96),
            const SizedBox(height: 16),
            Text(
              l10n.appTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
