import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/transactions/ledger_transaction_editor_sheet.dart';
import 'finko_shell_drawer.dart';
import 'shell_drawer_controller.dart';

/// App shell: [Scaffold] + bottom navigation + [Drawer].
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _plusSlotIndex = 2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _slotForBranch(int branchIndex) {
    return branchIndex < _plusSlotIndex ? branchIndex : branchIndex + 1;
  }

  int? _branchForSlot(int slotIndex) {
    if (slotIndex == _plusSlotIndex) {
      return null;
    }
    return slotIndex < _plusSlotIndex ? slotIndex : slotIndex - 1;
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _openCreateTransactionSheet(BuildContext context) async {
    await LedgerTransactionEditorSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ShellDrawerController(
      openDrawer: _openDrawer,
      child: Scaffold(
        key: _scaffoldKey,
        body: widget.navigationShell,
        drawer: Drawer(
          child: SafeArea(
            child: FinkoShellDrawer(navigationShell: widget.navigationShell),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _slotForBranch(widget.navigationShell.currentIndex),
          onDestinationSelected: (int slotIndex) {
            final branchIndex = _branchForSlot(slotIndex);
            if (branchIndex == null) {
              _openCreateTransactionSheet(context);
              return;
            }
            widget.navigationShell.goBranch(
              branchIndex,
              initialLocation:
                  branchIndex == widget.navigationShell.currentIndex,
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
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              selectedIcon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              label: l10n.navNewTransaction,
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
          ],
        ),
      ),
    );
  }
}
