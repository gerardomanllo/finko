import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/finko_account.dart';
import '../../../core/data/models/finko_category.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/budgets/finko_budget_progress_block.dart';
import '../../../widgets/budgets/finko_month_paginator_field.dart';
import '../../../widgets/categories/finko_category_icon_avatar.dart';
import '../../../widgets/charts/finko_donut_with_side_legend.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';
import '../../accounts/application/account_editor_bridge.dart';
import '../../onboarding/presentation/onboarding_account_editor.dart';
import '../../onboarding/presentation/onboarding_account_icons.dart';
import '../application/product_tutorial_controller.dart';
import '../application/tutorial_preview_providers.dart';
import '../domain/tutorial_target_id.dart';
import 'tutorial_preview_placeholders.dart';
import 'tutorial_target.dart';

/// Fixed-size donut preview for tour step 16 — always mounted when that step is active.
class TourSpendingDonutAnchor extends ConsumerWidget {
  const TourSpendingDonutAnchor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final main =
        ref.watch(userProfileStreamProvider).valueOrNull?.mainCurrency ?? 'MXN';
    final expense =
        ref.watch(tourAwareDashboardMonthTotalsProvider)?.expenseMinorMain ??
        75000;
    final fmt = formatMinorUnits(expense, main, locale);

    return TutorialTarget(
      id: TutorialTargetId.spendingDonut,
      child: FinkoPaperCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: SizedBox(
          height: 200,
          child: FinkoDonutWithSideLegend(
            sections: [
              PieChartSectionData(
                value: 1,
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
                radius: 10,
                title: '',
              ),
              PieChartSectionData(
                value: 1,
                color: theme.colorScheme.tertiary.withValues(alpha: 0.7),
                radius: 10,
                title: '',
              ),
            ],
            centerTitle: l10n.spendingTotalSpendIn,
            centerSubtitle: l10n.spendingPeriodMonth,
            centerTotal: fmt,
            legendRows: const [],
            centerSpaceRadius: 75,
            sectionsSpace: 0,
          ),
        ),
      ),
    );
  }
}

/// Categories body with a guaranteed spotlight target during the categories tour step.
class TourCategoriesBody extends ConsumerWidget {
  const TourCategoriesBody({super.key, required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catsAsync = ref.watch(categoriesStreamProvider);
    final monthAsync = ref.watch(currentMonthTotalsStreamProvider);
    final mainCurrency =
        ref.watch(userProfileStreamProvider).valueOrNull?.mainCurrency ?? 'MXN';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final byCategory = monthAsync.valueOrNull?.byCategoryMinorMain ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      child: catsAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return TutorialTarget(
              id: TutorialTargetId.categoriesFirstRow,
              child: TutorialCategoriesPreview(l10n: l10n),
            );
          }
          final first = categories.first;
          final monthMinor = byCategory[first.id] ?? 0;
          final sign = monthMinor >= 0 ? '+' : '−';
          final trailing =
              '$sign${formatMinorUnits(monthMinor.abs(), mainCurrency, locale)}';
          return TutorialTarget(
            id: TutorialTargetId.categoriesFirstRow,
            child: _TourCategoryRow(
              category: first,
              trailing: trailing,
            ),
          );
        },
        loading: () => TutorialTarget(
          id: TutorialTargetId.categoriesFirstRow,
          child: TutorialCategoriesPreview(l10n: l10n),
        ),
        error: (e, _) => TutorialTarget(
          id: TutorialTargetId.categoriesFirstRow,
          child: TutorialCategoriesPreview(l10n: l10n),
        ),
      ),
    );
  }
}

class _TourCategoryRow extends StatelessWidget {
  const _TourCategoryRow({
    required this.category,
    required this.trailing,
  });

  final FinkoCategory category;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return FinkoPaperCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
        leading: FinkoCategoryIconAvatar.fromCategory(category),
        title: Text(category.name),
        trailing: Text(
          trailing,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}

/// Accounts body with a guaranteed spotlight target during the accounts tour step.
class TourAccountsBody extends ConsumerWidget {
  const TourAccountsBody({super.key, required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(accountsStreamProvider);
    final mainCurrency =
        ref.watch(userProfileStreamProvider).valueOrNull?.mainCurrency ??
        async.valueOrNull?.firstOrNull?.currency ??
        'MXN';
    final locale = Localizations.localeOf(context).toLanguageTag();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(12, 16, 12, bottomInset),
      child: async.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return TutorialTarget(
              id: TutorialTargetId.accountsFirstRow,
              child: TutorialAccountsPreview(l10n: l10n),
            );
          }
          final first = accounts.first;
          return TutorialTarget(
            id: TutorialTargetId.accountsFirstRow,
            child: _TourAccountRow(
              account: first,
              mainCurrency: mainCurrency,
              locale: locale,
              l10n: l10n,
            ),
          );
        },
        loading: () => TutorialTarget(
          id: TutorialTargetId.accountsFirstRow,
          child: TutorialAccountsPreview(l10n: l10n),
        ),
        error: (e, _) => TutorialTarget(
          id: TutorialTargetId.accountsFirstRow,
          child: TutorialAccountsPreview(l10n: l10n),
        ),
      ),
    );
  }
}

class _TourAccountRow extends StatelessWidget {
  const _TourAccountRow({
    required this.account,
    required this.mainCurrency,
    required this.locale,
    required this.l10n,
  });

  final FinkoAccount account;
  final String mainCurrency;
  final String locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isForeign = account.currency != mainCurrency;
    final mainAmount = formatMinorUnits(
      account.balanceMinorMain ?? account.balanceMinor,
      mainCurrency,
      locale,
    );
    final actualAmount = formatMinorUnitsWithCode(
      account.balanceMinor,
      account.currency,
      locale,
    );
    final bg = account.colorArgb;
    final leading = CircleAvatar(
      backgroundColor: bg != null ? Color(bg) : null,
      child: Icon(
        onboardingAccountIconForKey(account.iconKey),
        color: bg != null ? Colors.white : null,
      ),
    );

    return FinkoPaperCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
        leading: leading,
        title: Text(account.name),
        subtitle: Text(
          accountTypeLabel(
            l10n,
            onboardingAccountTypeFromFinko(account.type),
          ),
        ),
        trailing: isForeign
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [Text('~$mainAmount'), Text(actualAmount)],
              )
            : Text(mainAmount, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

/// Budgets header with paginator target during the budgets tour step.
class TourBudgetsBody extends ConsumerWidget {
  const TourBudgetsBody({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final main =
        ref.watch(userProfileStreamProvider).valueOrNull?.mainCurrency ?? 'MXN';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final ym =
        '${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}';
    final expense =
        ref.watch(tourAwareMonthTotalsProvider(ym))?.expenseMinorMain ?? 75000;
    final budgeted = 75000;
    final left = (budgeted - expense).clamp(0, budgeted);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TutorialTarget(
          id: TutorialTargetId.budgetsMonthPaginator,
          child: FinkoMonthPaginatorField(
            month: month,
            thisMonthLabel: l10n.budgetsThisMonth,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
        ),
        const SizedBox(height: 20),
        FinkoBudgetProgressBlock(
          title: l10n.budgetsSpendingTitle,
          leftLabel: l10n.leftForSpending,
          leftAmountText: formatMinorUnits(left, main, locale),
          spentLabel: l10n.budgetsSpent,
          spentAmountText: formatMinorUnits(expense, main, locale),
          budgetedLabel: l10n.budgetsBudgeted,
          budgetedAmountText: formatMinorUnits(budgeted, main, locale),
          progress: budgeted > 0 ? (expense / budgeted).clamp(0.0, 1.0) : 0.0,
        ),
        const SizedBox(height: 12),
        TutorialPreviewListRow(
          title: l10n.tutorialPreviewCategoryExpense,
          subtitle: l10n.tutorialPreviewBudgetSample,
          trailing: formatMinorUnits(15000, main, locale),
        ),
      ],
    );
  }
}

bool isTourStep(WidgetRef ref, String stepId) {
  final s = ref.watch(productTutorialControllerProvider);
  return s.active && s.currentStep?.id == stepId;
}
