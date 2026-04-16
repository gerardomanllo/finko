import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_environment.dart';
import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/locale/app_environment_provider.dart';
import '../../../l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final env = ref.watch(appEnvironmentProvider);
    final envLabel = env == AppEnvironment.dev ? 'DEV' : 'PROD';
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.environmentBanner(envLabel),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (user?.email != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.dashboardSignedInAs(user!.email!),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.dashboardHeadline,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.push('/settings'),
              child: Text(l10n.openSettings),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/onboarding'),
              child: Text(l10n.openOnboarding),
            ),
          ],
        ),
      ),
    );
  }
}
