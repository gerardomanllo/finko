import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/transactions/ledger_transaction_editor_sheet.dart';
import 'finko_shell_drawer.dart';
import 'shell_drawer_controller.dart';

/// Chrome behind the shell [NavigationBar]: [Material] elevation mostly casts
/// shadow *below* the bar (often off-screen), so we paint an explicit upward
/// shadow plus a hairline so the bar reads above the content.
Widget _shellBottomNavChrome(BuildContext context, {required Widget child}) {
  final theme = Theme.of(context);
  final Color barBg =
      theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.surface;
  final bool isDark = theme.brightness == Brightness.dark;

  final List<BoxShadow> shadows = isDark
      ? <BoxShadow>[
          BoxShadow(
            offset: const Offset(0, -6),
            blurRadius: 28,
            color: Colors.black.withValues(alpha: 0.44),
          ),
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.32),
          ),
        ]
      : <BoxShadow>[
          BoxShadow(
            offset: const Offset(0, -6),
            blurRadius: 24,
            color: Colors.black.withValues(alpha: 0.17),
          ),
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ];

  return DecoratedBox(
    decoration: BoxDecoration(
      color: barBg,
      border: Border(
        top: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.09),
        ),
      ),
      boxShadow: shadows,
    ),
    child: child,
  );
}

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
        bottomNavigationBar: _shellBottomNavChrome(
          context,
          child: NavigationBar(
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
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
      ),
    );
  }
}
