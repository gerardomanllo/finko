import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/budget/monthly_budget_rollup.dart';
import '../../../core/budget/spending_pace.dart';
import '../../../core/data/models/finko_category.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/monthly_totals.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/ui/category_accent_color.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/budgets/finko_budget_compact_summary_card.dart';
import '../../../widgets/budgets/finko_budget_progress_block.dart';
import '../../../widgets/budgets/finko_category_avatar_ring.dart';
import '../../../widgets/budgets/finko_month_paginator_field.dart';
import '../../../widgets/budgets/finko_savings_projection_card.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';

String _yyyyMm(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}';
}

DateTime _addMonths(DateTime d, int delta) {
  return DateTime(d.year, d.month + delta, d.day);
}

Map<String, FinkoCategory> _categoryMap(Iterable<FinkoCategory> list) {
  return {for (final c in list) c.id: c};
}

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
  }

  String _fmt(BuildContext context, int minor, String code) {
    final loc = Localizations.localeOf(context).toLanguageTag();
    return formatMinorUnits(minor, code, loc);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ym = _yyyyMm(_month);
    final totalsAsync = ref.watch(monthlyTotalsForMonthStreamProvider(ym));
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final main = profile?.mainCurrency ?? 'MXN';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FinkoMonthPaginatorField(
            month: _month,
            thisMonthLabel: l10n.budgetsThisMonth,
            onPrevious: () => setState(() => _month = _addMonths(_month, -1)),
            onNext: () => setState(() => _month = _addMonths(_month, 1)),
          ),
          const SizedBox(height: 20),
          totalsAsync.when(
            data: (m) {
              if (m == null) {
                return Text(l10n.emptyNoMonthlyTotals);
              }
              return categoriesAsync.when(
                data: (categories) {
                  final catById = _categoryMap(categories);
                  final budgets = profile?.budgets ?? const {};
                  final budgeted = totalExpenseBudgetMinor(budgets);
                  final spent = m.expenseMinorMain;
                  final left = (budgeted - spent).clamp(0, 1 << 62);
                  final progress = budgeted > 0
                      ? (spent / budgeted).clamp(0.0, 1.0)
                      : 0.0;
                  final today = DateTime.now();
                  final daysRem = calendarDaysRemainingInViewedMonth(
                    _month,
                    today,
                  );
                  final String? paceText = budgeted > 0 && daysRem > 0
                      ? l10n.budgetsSpendingPace(
                          '${_fmt(context, paceMinorPerDay(leftMinor: left, daysRemaining: daysRem), main)}${l10n.budgetsPaceSlashDay}',
                          l10n.budgetsDaysRemainingInMonth(daysRem),
                        )
                      : null;

                  final fixed = fixedExpensesBudgetAndSpent(m, budgets);
                  final billsBudgeted = fixed.budgetedMinor;
                  final billsSpent = fixed.spentMinor;
                  final billsLeft = (billsBudgeted - billsSpent).clamp(
                    0,
                    1 << 62,
                  );
                  final billsProgress = billsBudgeted > 0
                      ? (billsSpent / billsBudgeted).clamp(0.0, 1.0)
                      : 0.0;

                  final incomeTargetX = incomeCategoryBudgetTargetMinor(
                    budgets,
                    categories,
                  );
                  final incomeActualY = m.incomeMinorMain;
                  final incomeLeft = (incomeTargetX - incomeActualY).clamp(
                    0,
                    1 << 62,
                  );
                  final incomeProgress = incomeTargetX > 0
                      ? (incomeActualY / incomeTargetX).clamp(0.0, 1.0)
                      : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FinkoBudgetProgressBlock(
                        title: l10n.budgetsSpendingTitle,
                        leftLabel: l10n.leftForSpending,
                        leftAmountText: _fmt(context, left, main),
                        spentLabel: l10n.budgetsSpent,
                        spentAmountText: _fmt(context, spent, main),
                        budgetedLabel: l10n.budgetsBudgeted,
                        budgetedAmountText: _fmt(context, budgeted, main),
                        progress: progress,
                        paceText: paceText,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FinkoBudgetCompactSummaryCard(
                              icon: Icons.receipt_long_outlined,
                              title: l10n.budgetsBillsUtilities,
                              primaryAmountText: _fmt(context, billsLeft, main),
                              primaryCaptionText:
                                  l10n.budgetsCompactBillsCaption,
                              progress: billsProgress,
                              footerText: l10n.budgetsCompactAmountPaid(
                                _fmt(context, billsSpent, main),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FinkoBudgetCompactSummaryCard(
                              icon: Icons.savings_outlined,
                              title: l10n.budgetsEarnings,
                              primaryAmountText: _fmt(
                                context,
                                incomeLeft,
                                main,
                              ),
                              primaryCaptionText:
                                  l10n.budgetsCompactEarningsCaption,
                              progress: incomeProgress,
                              footerText: l10n.budgetsCompactAmountEarned(
                                _fmt(context, incomeActualY, main),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FinkoSavingsProjectionCard(
                        title: l10n.budgetsProjectedSavings,
                        projectedAmountText: _fmt(context, left ~/ 2, main),
                        targetAmountText: l10n.budgetsOfTarget(
                          _fmt(context, budgeted ~/ 4, main),
                        ),
                        projectedFraction: budgeted > 0 ? 0.45 : 0.3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.budgetsCategoryBudgets,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _CategoryBudgetList(
                        month: m,
                        budgets: budgets,
                        categoryById: catById,
                        formatMoney: (x) => _fmt(context, x, main),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetList extends StatelessWidget {
  const _CategoryBudgetList({
    required this.month,
    required this.budgets,
    required this.categoryById,
    required this.formatMoney,
  });

  final MonthlyTotals month;
  final Map<String, MonthlyBudgetEntry> budgets;
  final Map<String, FinkoCategory> categoryById;
  final String Function(int minor) formatMoney;

  @override
  Widget build(BuildContext context) {
    final expenseRows = <MapEntry<String, MonthlyBudgetEntry>>[];
    for (final e in budgets.entries) {
      if (e.value.kind != BudgetKind.expense) continue;
      final cat = categoryById[e.key];
      if (cat != null && cat.kind == CategoryKind.income) continue;
      expenseRows.add(e);
    }
    expenseRows.sort((a, b) {
      final cmp = b.value.targetMinorMain.compareTo(a.value.targetMinorMain);
      if (cmp != 0) return cmp;
      return a.key.compareTo(b.key);
    });
    return FinkoPaperCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in expenseRows)
            _CategoryRow(
              categoryId: e.key,
              entry: e.value,
              signedNet: month.byCategoryMinorMain[e.key] ?? 0,
              category: categoryById[e.key],
              formatMoney: formatMoney,
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryId,
    required this.entry,
    required this.signedNet,
    required this.category,
    required this.formatMoney,
  });

  final String categoryId;
  final MonthlyBudgetEntry entry;
  final int signedNet;
  final FinkoCategory? category;
  final String Function(int minor) formatMoney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final target = entry.targetMinorMain;
    final actualPositive = positiveExpenseMinorFromSignedNet(signedNet);
    final ring = target > 0 ? (actualPositive / target).clamp(0.0, 1.0) : 0.5;
    final overBudget = target > 0 && actualPositive > target;
    final String subtitleText;
    if (actualPositive <= target) {
      final leftMinor = (target - actualPositive).clamp(0, 1 << 62);
      subtitleText = l10n.budgetsCategorySubtitleRemaining(
        formatMoney(leftMinor),
      );
    } else {
      final overMinor = actualPositive - target;
      subtitleText = l10n.budgetsCategorySubtitleOver(formatMoney(overMinor));
    }
    final titleName = category?.name ?? categoryId;
    final avatarLabel = titleName.isNotEmpty ? titleName : categoryId;
    final ringColor = categoryAccentColor(
      theme.colorScheme,
      categoryId,
      colorArgb: category?.colorArgb,
    );
    const ringSize = 46.0;
    final avatarRing = FinkoCategoryAvatarRing(
      label: avatarLabel,
      iconKey: category?.iconKey ?? 'category',
      categoryId: categoryId,
      colorArgb: category?.colorArgb,
      progress: ring,
      ringColor: ringColor,
    );
    return ListTile(
      leading: SizedBox(
        width: ringSize,
        height: ringSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            avatarRing,
            if (overBudget)
              Positioned(
                top: -2,
                right: -2,
                child: Tooltip(
                  message: l10n.budgetsCategoryOverBudgetTooltip,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: 0.18,
                          ),
                          blurRadius: 2,
                          offset: const Offset(0, 0.5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(titleName),
      subtitle: Text(subtitleText),
      trailing: Text(
        formatMoney(actualPositive),
        style: theme.textTheme.titleSmall,
      ),
    );
  }
}
