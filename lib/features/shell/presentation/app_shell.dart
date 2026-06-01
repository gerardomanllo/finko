import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/transactions/ledger_transaction_editor_sheet.dart';
import '../../agent/presentation/agent_entry_pill.dart';
import '../../product_tutorial/application/tutorial_shell_host.dart';
import '../../product_tutorial/domain/tutorial_target_id.dart';
import '../../product_tutorial/presentation/tutorial_target.dart';
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
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const int _plusSlotIndex = 2;
  static const Set<String> _agentPillTabPaths = {
    '/dashboard',
    '/recurring',
    '/spending',
    '/transactions',
  };

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _drawerOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerTutorialShellHost());
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell != widget.navigationShell) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _registerTutorialShellHost());
    }
  }

  @override
  void dispose() {
    final hostNotifier = ref.read(tutorialShellHostProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hostNotifier.state = null;
    });
    super.dispose();
  }

  void _registerTutorialShellHost() {
    if (!mounted) return;
    final scroll = ref.read(dashboardScrollControllerProvider);
    ref.read(tutorialShellHostProvider.notifier).state = TutorialShellHost(
      openDrawer: _openDrawer,
      closeDrawer: () => _scaffoldKey.currentState?.closeDrawer(),
      navigationShell: widget.navigationShell,
      scaffoldKey: _scaffoldKey,
      scrollDashboardToTop: scroll != null
          ? () {
              if (scroll.hasClients) scroll.jumpTo(0);
            }
          : null,
    );
  }

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

  bool _showAgentPill(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (!_agentPillTabPaths.contains(location)) return false;
    if (_drawerOpen) return false;
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) return false;
    return true;
  }

  Widget _plusNavIconInner(BuildContext context, {required bool selected}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add,
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showPill = _showAgentPill(context);

    return ShellDrawerController(
      openDrawer: _openDrawer,
      child: Scaffold(
        key: _scaffoldKey,
        onDrawerChanged: (open) => setState(() => _drawerOpen = open),
        body: Stack(
          fit: StackFit.expand,
          children: [
            widget.navigationShell,
            if (showPill)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: TutorialTarget(
                    id: TutorialTargetId.agentEntryPill,
                    child: const AgentEntryPill(),
                  ),
                ),
              ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: FinkoShellDrawer(navigationShell: widget.navigationShell),
          ),
        ),
        bottomNavigationBar: TutorialTarget(
          id: TutorialTargetId.shellBottomNav,
          child: _shellBottomNavChrome(
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
                icon: TutorialTarget(
                  id: TutorialTargetId.shellNewTransaction,
                  child: _plusNavIconInner(context, selected: false),
                ),
                selectedIcon: _plusNavIconInner(context, selected: true),
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
      ),
    );
  }
}
