import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/upcoming_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import 'tutorial_step.dart';
import 'tutorial_target_id.dart';

/// Ordered product tour steps (24).
final List<TutorialStep> kProductTutorialCatalog = <TutorialStep>[
  const TutorialStep(
    id: 'welcome',
    titleKey: 'tutorialWelcomeTitle',
    bodyKey: 'tutorialWelcomeBody',
    spotlightShape: TutorialSpotlightShape.none,
    preAction: TutorialPreAction.goDashboard,
  ),
  const TutorialStep(
    id: 'shell_bottom_nav',
    titleKey: 'tutorialNavBottomTitle',
    bodyKey: 'tutorialNavBottomBody',
    targetId: TutorialTargetId.shellBottomNav,
    preAction: TutorialPreAction.closeDrawer,
  ),
  const TutorialStep(
    id: 'shell_menu_cog',
    titleKey: 'tutorialMenuCogTitle',
    bodyKey: 'tutorialMenuCogBody',
    targetId: TutorialTargetId.shellMenuCog,
  ),
  const TutorialStep(
    id: 'drawer_snapshot',
    titleKey: 'tutorialDrawerSnapshotTitle',
    bodyKey: 'tutorialDrawerSnapshotBody',
    targetId: TutorialTargetId.drawerSnapshot,
    preAction: TutorialPreAction.openDrawer,
  ),
  const TutorialStep(
    id: 'drawer_nav',
    titleKey: 'tutorialDrawerNavTitle',
    bodyKey: 'tutorialDrawerNavBody',
    targetId: TutorialTargetId.drawerNav,
    preAction: TutorialPreAction.openDrawer,
  ),
  const TutorialStep(
    id: 'dashboard_carousel',
    titleKey: 'tutorialDashboardCarouselTitle',
    bodyKey: 'tutorialDashboardCarouselBody',
    targetId: TutorialTargetId.dashboardMetricCarousel,
    preAction: TutorialPreAction.closeDrawer,
  ),
  const TutorialStep(
    id: 'dashboard_accounts',
    titleKey: 'tutorialDashboardAccountsTitle',
    bodyKey: 'tutorialDashboardAccountsBody',
    targetId: TutorialTargetId.dashboardAccountsAccordion,
  ),
  TutorialStep(
    id: 'dashboard_upcoming',
    titleKey: 'tutorialDashboardUpcomingTitle',
    bodyKey: 'tutorialDashboardUpcomingBody',
    targetId: TutorialTargetId.dashboardUpcomingStrip,
    skipWhen: (Ref ref) {
      final strip =
          ref.read(dashboardUpcomingStripProvider).valueOrNull ??
          const <UpcomingTransaction>[];
      return strip.isEmpty;
    },
  ),
  const TutorialStep(
    id: 'dashboard_budget',
    titleKey: 'tutorialDashboardBudgetTitle',
    bodyKey: 'tutorialDashboardBudgetBody',
    targetId: TutorialTargetId.dashboardBudgetTeaser,
  ),
  const TutorialStep(
    id: 'recurring_calendar',
    titleKey: 'tutorialRecurringCalendarTitle',
    bodyKey: 'tutorialRecurringCalendarBody',
    targetId: TutorialTargetId.recurringCalendar,
    preAction: TutorialPreAction.goRecurring,
  ),
  const TutorialStep(
    id: 'recurring_due_soon',
    titleKey: 'tutorialRecurringDueSoonTitle',
    bodyKey: 'tutorialRecurringDueSoonBody',
    targetId: TutorialTargetId.recurringDueSoon,
  ),
  const TutorialStep(
    id: 'recurring_coming_later',
    titleKey: 'tutorialRecurringComingLaterTitle',
    bodyKey: 'tutorialRecurringComingLaterBody',
    targetId: TutorialTargetId.recurringComingLater,
  ),
  const TutorialStep(
    id: 'new_transaction',
    titleKey: 'tutorialNewTransactionTitle',
    bodyKey: 'tutorialNewTransactionBody',
    targetId: TutorialTargetId.shellNewTransaction,
    preAction: TutorialPreAction.goDashboard,
    spotlightShape: TutorialSpotlightShape.circle,
  ),
  const TutorialStep(
    id: 'spending_pill',
    titleKey: 'tutorialSpendingPillTitle',
    bodyKey: 'tutorialSpendingPillBody',
    targetId: TutorialTargetId.spendingPeriodPill,
    preAction: TutorialPreAction.goSpending,
  ),
  const TutorialStep(
    id: 'spending_strip',
    titleKey: 'tutorialSpendingStripTitle',
    bodyKey: 'tutorialSpendingStripBody',
    targetId: TutorialTargetId.spendingPeriodStrip,
  ),
  const TutorialStep(
    id: 'spending_donut',
    titleKey: 'tutorialSpendingDonutTitle',
    bodyKey: 'tutorialSpendingDonutBody',
    targetId: TutorialTargetId.spendingDonut,
    maxSpotlightHeight: 220,
    maxSpotlightWidth: 340,
  ),
  const TutorialStep(
    id: 'transactions_search',
    titleKey: 'tutorialTransactionsSearchTitle',
    bodyKey: 'tutorialTransactionsSearchBody',
    targetId: TutorialTargetId.transactionsFilterButton,
    preAction: TutorialPreAction.goTransactions,
  ),
  const TutorialStep(
    id: 'transactions_list',
    titleKey: 'tutorialTransactionsListTitle',
    bodyKey: 'tutorialTransactionsListBody',
    targetId: TutorialTargetId.transactionsListFirstRow,
    scrollIntoView: false,
    maxSpotlightHeight: 72,
  ),
  const TutorialStep(
    id: 'categories',
    titleKey: 'tutorialCategoriesTitle',
    bodyKey: 'tutorialCategoriesBody',
    targetId: TutorialTargetId.categoriesFirstRow,
    preAction: TutorialPreAction.pushCategories,
    maxSpotlightHeight: 88,
  ),
  const TutorialStep(
    id: 'accounts',
    titleKey: 'tutorialAccountsTitle',
    bodyKey: 'tutorialAccountsBody',
    targetId: TutorialTargetId.accountsFirstRow,
    preAction: TutorialPreAction.pushAccounts,
    maxSpotlightHeight: 88,
  ),
  const TutorialStep(
    id: 'budgets',
    titleKey: 'tutorialBudgetsTitle',
    bodyKey: 'tutorialBudgetsBody',
    targetId: TutorialTargetId.budgetsMonthPaginator,
    preAction: TutorialPreAction.pushBudgets,
    maxSpotlightHeight: 56,
  ),
  const TutorialStep(
    id: 'settings',
    titleKey: 'tutorialSettingsTitle',
    bodyKey: 'tutorialSettingsBody',
    targetId: TutorialTargetId.settingsAppearance,
    preAction: TutorialPreAction.pushSettings,
  ),
  const TutorialStep(
    id: 'agent_pill',
    titleKey: 'tutorialAgentTitle',
    bodyKey: 'tutorialAgentBody',
    targetId: TutorialTargetId.agentEntryPill,
    preAction: TutorialPreAction.popToShellDashboard,
    spotlightShape: TutorialSpotlightShape.pill,
    spotlightPadding: 6,
    scrollIntoView: false,
  ),
  const TutorialStep(
    id: 'done',
    titleKey: 'tutorialDoneTitle',
    bodyKey: 'tutorialDoneBody',
    spotlightShape: TutorialSpotlightShape.none,
  ),
];
