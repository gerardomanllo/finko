import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

/// App shell: [Scaffold] + bottom navigation + [Drawer] from **More** (see `docs/shell-navigation.md`).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    void openDrawer() {
      scaffoldKey.currentState?.openDrawer();
    }

    return Scaffold(
      key: scaffoldKey,
      body: navigationShell,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(l10n.drawerUserPlaceholderName),
                accountEmail: Text(l10n.drawerUserPlaceholderEmail),
                currentAccountPicture: CircleAvatar(
                  child: Text(l10n.drawerUserPlaceholderInitial),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(l10n.drawerCategories),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/categories');
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n.drawerAccounts),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/accounts');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(l10n.settingsTitle),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          if (index == 4) {
            openDrawer();
            return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.repeat_outlined),
            selectedIcon: const Icon(Icons.repeat),
            label: l10n.navRecurring,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: l10n.navSpending,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more_horiz),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}
