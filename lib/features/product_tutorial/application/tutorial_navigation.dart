import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../domain/tutorial_step.dart';
import '../domain/tutorial_target_id.dart';
import 'tutorial_shell_host.dart';
import 'tutorial_target_registry.dart';

/// Bumps when shell tab content scrolls so the overlay can remeasure targets.
final tutorialScrollTickProvider = StateProvider<int>((ref) => 0);

String? _stackPathForStepId(String stepId) {
  return switch (stepId) {
    'categories' => '/categories',
    'accounts' => '/accounts',
    'budgets' => '/budgets',
    'settings' => '/settings',
    _ => null,
  };
}

int? _shellBranchForStepId(String stepId) {
  return switch (stepId) {
    'welcome' ||
    'shell_bottom_nav' ||
    'shell_menu_cog' ||
    'dashboard_carousel' ||
    'dashboard_accounts' ||
    'dashboard_upcoming' ||
    'dashboard_budget' ||
    'new_transaction' ||
    'agent_pill' ||
    'done' => 0,
    'recurring_calendar' ||
    'recurring_due_soon' ||
    'recurring_coming_later' => 1,
    'spending_pill' || 'spending_strip' || 'spending_donut' => 2,
    'transactions_search' || 'transactions_list' => 3,
    _ => null,
  };
}

bool _drawerOpenForStepId(String stepId) {
  return stepId == 'drawer_snapshot' || stepId == 'drawer_nav';
}

GoRouter? _readGoRouterOrNull(Ref ref) {
  try {
    return ref.read(goRouterProvider);
  } on Object {
    return null;
  }
}

Future<void> syncNavigationForStep(Ref ref, TutorialStep step) async {
  final hostBefore = ref.read(tutorialShellHostProvider) != null;
  if (!hostBefore) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  final h = ref.read(tutorialShellHostProvider);
  final router = _readGoRouterOrNull(ref);
  final stackPath = _stackPathForStepId(step.id);

  if (stackPath != null) {
    if (router != null) {
      while (router.canPop()) {
        router.pop();
      }
    }
    final branch = _shellBranchForStepId(step.id);
    if (branch != null) {
      h?.navigationShell.goBranch(branch, initialLocation: true);
    }
    h?.closeDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    router?.push(stackPath);
    await Future<void>.delayed(const Duration(milliseconds: 480));
    return;
  }

  if (router != null) {
    while (router.canPop()) {
      router.pop();
    }
  }

  final branch = _shellBranchForStepId(step.id);
  if (branch != null) {
    h?.navigationShell.goBranch(branch, initialLocation: true);
  }

  if (_drawerOpenForStepId(step.id)) {
    h?.openDrawer();
  } else {
    h?.closeDrawer();
  }

  await Future<void>.delayed(const Duration(milliseconds: 320));
}

Future<void> resetTourHome(Ref ref) async {
  final router = _readGoRouterOrNull(ref);
  if (router != null) {
    while (router.canPop()) {
      router.pop();
    }
  }
  final h = ref.read(tutorialShellHostProvider);
  h?.closeDrawer();
  h?.navigationShell.goBranch(0, initialLocation: true);
  h?.scrollDashboardToTop?.call();
  await Future<void>.delayed(const Duration(milliseconds: 120));
}

Future<void> prepareTutorialStep(Ref ref, TutorialStep step) async {
  await syncNavigationForStep(ref, step);
  final targetId = step.targetId;
  if (targetId == null) return;

  final registry = ref.read(tutorialTargetRegistryProvider.notifier);
  final pollAttempts = switch (step.id) {
    'recurring_calendar' => 48,
    'spending_donut' => 48,
    'categories' || 'accounts' || 'budgets' => 48,
    _ => 28,
  };
  Rect? rect;
  for (var attempt = 0; attempt < pollAttempts; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    rect = registry.rectFor(targetId);
    if (rect != null) break;
  }

  final shouldScroll = step.scrollIntoView ||
      targetId == TutorialTargetId.categoriesFirstRow ||
      targetId == TutorialTargetId.accountsFirstRow ||
      targetId == TutorialTargetId.budgetsMonthPaginator ||
      targetId == TutorialTargetId.spendingDonut;

  if (rect != null && shouldScroll) {
    final alignment = switch (targetId) {
      TutorialTargetId.dashboardAccountsAccordion => 0.35,
      TutorialTargetId.spendingDonut => 0.15,
      _ => 0.2,
    };
    await registry.ensureVisible(
      targetId,
      alignment: alignment,
      duration: targetId == TutorialTargetId.dashboardAccountsAccordion
          ? const Duration(milliseconds: 220)
          : const Duration(milliseconds: 280),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    ref.read(tutorialScrollTickProvider.notifier).state++;
  } else {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      rect = registry.rectFor(targetId);
      if (rect != null) {
        ref.read(tutorialScrollTickProvider.notifier).state++;
        break;
      }
    }
  }
}
