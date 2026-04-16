import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/app_environment.dart';
import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/locale/app_environment_provider.dart';
import '../../../l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static String _formatMinor(int minor, String currencyCode) {
    final fmt = NumberFormat.currency(
      locale: 'en_US',
      name: currencyCode,
      symbol: '',
      decimalDigits: 2,
    );
    return '${fmt.format(minor / 100.0).trim()} $currencyCode';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final env = ref.watch(appEnvironmentProvider);
    final envLabel = env == AppEnvironment.dev ? 'DEV' : 'PROD';
    final user = ref.watch(authStateProvider).valueOrNull;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final monthAsync = ref.watch(currentMonthTotalsStreamProvider);
    final recentAsync = ref.watch(recentTransactionsStreamProvider);
    final upcomingAsync = ref.watch(upcomingTransactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 24),
          Text(
            'This month (main currency)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          monthAsync.when(
            data: (m) {
              if (m == null) {
                return const Text('No monthly totals yet — add a transaction.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Income: ${_formatMinor(m.incomeMinorMain, 'MXN')}'),
                  Text('Expense: ${_formatMinor(m.expenseMinorMain, 'MXN')}'),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),
          Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          accountsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text('No accounts yet.');
              }
              return Column(
                children: list
                    .map(
                      (a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(a.name),
                        subtitle: Text(a.type.wireName),
                        trailing: Text(
                          _formatMinor(a.balanceMinor, a.currency),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent transactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          recentAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text('No transactions yet.');
              }
              return Column(
                children: list
                    .map(
                      (t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.memo ?? t.type.wireName),
                        subtitle: Text(t.transactionDate),
                        trailing: Text(
                          '${t.direction.wireName} ${_formatMinor(t.amountMinor, t.currency)}',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),
          Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          upcomingAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text('Nothing upcoming from today onward.');
              }
              return Column(
                children: list
                    .map(
                      (u) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(u.memo ?? u.kind.wireName),
                        subtitle: Text(u.transactionDate),
                        trailing: Text(
                          '${u.direction.wireName} ${_formatMinor(u.amountMinor, u.currency)}',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 32),
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
    );
  }
}
