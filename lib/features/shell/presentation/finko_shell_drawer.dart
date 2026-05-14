import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/models/finko_account.dart';
import '../../../core/data/models/finko_account_kind.dart';
import '../../../core/data/monthly_totals_as_of_date.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/finko_theme.dart';
import '../../../l10n/app_localizations.dart';

Color _drawerMutedFill(ThemeData theme) {
  return theme.brightness == Brightness.light
      ? FinkoColors.cloud
      : FinkoColors.navy700;
}

Color _drawerNavSelectedFill(ThemeData theme) {
  return theme.brightness == Brightness.light
      ? FinkoColors.cloud
      : FinkoColors.navy700;
}

Color _drawerNavSelectedIconFill(ThemeData theme) {
  return theme.brightness == Brightness.light
      ? Colors.white
      : FinkoColors.navy800;
}

/// Rich navigation drawer: profile, month snapshot, shell + stack destinations.
class FinkoShellDrawer extends ConsumerWidget {
  const FinkoShellDrawer({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static String _formatMoney(
    BuildContext context,
    int minor,
    String currencyCode,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return formatMinorUnits(minor, currencyCode, locale);
  }

  void _closeDrawer(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semantic = theme.extension<FinkoSemanticColors>();

    final location = GoRouterState.of(context).matchedLocation;
    final isHome = location == '/dashboard';
    final isCategories = location == '/categories';
    final isAccounts = location == '/accounts';
    final isSettings = location == '/settings';

    final accountsAsync = ref.watch(accountsStreamProvider);
    final userProfileAsync = ref.watch(userProfileStreamProvider);
    final todayKey = ref.watch(todayYyyyMmDdProvider);
    final ym = ref.watch(dashboardYearMonthProvider);
    final monthAsync = ref.watch(monthlyTotalsForMonthStreamProvider(ym));
    final sparkline = ref.watch(netWorthSparklineSeriesProvider);

    final mainCurrency =
        userProfileAsync.valueOrNull?.mainCurrency ??
        accountsAsync.valueOrNull?.firstOrNull?.currency ??
        'MXN';

    final profile = userProfileAsync.valueOrNull;
    final displayName = (profile?.displayName ?? '').trim();
    final nameText = displayName.isNotEmpty
        ? displayName
        : l10n.drawerUserPlaceholderName;
    final initial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : l10n.drawerUserPlaceholderInitial;

    final accounts = accountsAsync.valueOrNull ?? const <FinkoAccount>[];
    final netWorthFromAccounts = netWorthFromAccountsMinor(accounts);
    final hasSparklinePoints = sparkline.any((point) => point != 0);
    final netWorthDisplayMinor = hasSparklinePoints
        ? sparkline.last.toInt()
        : netWorthFromAccounts;

    final month = monthAsync.valueOrNull;
    final incomeMtd = month == null
        ? null
        : incomeMinorMainThroughDate(month, todayKey);
    final expenseMtd = month == null
        ? null
        : expenseMinorMainThroughDate(month, todayKey);

    double? savingsRate;
    if (incomeMtd != null && expenseMtd != null && incomeMtd > 0) {
      savingsRate = ((incomeMtd - expenseMtd) / incomeMtd).clamp(0.0, 1.0);
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final savingsText = savingsRate == null
        ? '—'
        : NumberFormat.percentPattern(localeTag).format(savingsRate);

    final incomeText = monthAsync.isLoading
        ? '…'
        : incomeMtd == null
        ? '—'
        : _formatMoney(context, incomeMtd, mainCurrency);
    final expenseText = monthAsync.isLoading
        ? '…'
        : expenseMtd == null
        ? '—'
        : _formatMoney(context, expenseMtd, mainCurrency);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _drawerMutedFill(theme),
              foregroundColor: scheme.primary,
              child: Text(
                initial,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    labelPadding: EdgeInsets.zero,
                    side: BorderSide(
                      color: theme.brightness == Brightness.light
                          ? FinkoColors.grayLight
                          : FinkoColors.grayDark,
                    ),
                    backgroundColor: _drawerMutedFill(theme),
                    label: Text(
                      l10n.drawerPlanFree,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Material(
          color: scheme.surface,
          surfaceTintColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.metricNetWorth,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                accountsAsync.maybeWhen(
                  data: (_) => Text(
                    _formatMoney(context, netWorthDisplayMinor, mainCurrency),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  orElse: () => Text(
                    '—',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.drawerNetWorthDeltaStub,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DrawerStatCell(
                label: l10n.drawerStatsIncomeLabel,
                valueText: incomeText,
                valueColor: semantic?.income ?? FinkoColors.income,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DrawerStatCell(
                label: l10n.drawerStatsExpenseLabel,
                valueText: expenseText,
                valueColor: semantic?.expense ?? FinkoColors.expense,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DrawerStatCell(
                label: l10n.drawerStatsSavingsLabel,
                valueText: savingsText,
                valueColor:
                    theme.textTheme.titleSmall?.color ?? scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.drawerNavSectionTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _DrawerNavRow(
          selected: isHome,
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: l10n.navDashboard,
          onTap: () {
            _closeDrawer(context);
            navigationShell.goBranch(0, initialLocation: true);
          },
        ),
        _DrawerNavRow(
          selected: isCategories,
          icon: Icons.category_outlined,
          selectedIcon: Icons.category,
          label: l10n.drawerCategories,
          onTap: () {
            _closeDrawer(context);
            context.push('/categories');
          },
        ),
        _DrawerNavRow(
          selected: isAccounts,
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          label: l10n.drawerAccounts,
          onTap: () {
            _closeDrawer(context);
            context.push('/accounts');
          },
        ),
        _DrawerNavRow(
          selected: isSettings,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: l10n.settingsTitle,
          onTap: () {
            _closeDrawer(context);
            context.push('/settings');
          },
        ),
      ],
    );
  }
}

class _DrawerStatCell extends StatelessWidget {
  const _DrawerStatCell({
    required this.label,
    required this.valueText,
    required this.valueColor,
  });

  final String label;
  final String valueText;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _drawerMutedFill(theme),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              valueText,
              style: theme.textTheme.titleSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavRow extends StatelessWidget {
  const _DrawerNavRow({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconBg = selected
        ? _drawerNavSelectedIconFill(theme)
        : _drawerMutedFill(theme);
    final iconFg = selected ? scheme.primary : scheme.onSurfaceVariant;
    final textStyle = theme.textTheme.titleSmall?.copyWith(
      color: selected ? scheme.primary : scheme.onSurface,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? _drawerNavSelectedFill(theme) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      selected ? selectedIcon : icon,
                      size: 22,
                      color: iconFg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: textStyle)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
