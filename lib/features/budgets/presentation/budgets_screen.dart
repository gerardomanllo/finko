import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/budget/spending_pace.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/monthly_totals.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
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
    const main = 'MXN';

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
              final budgeted = m.budgets.values
                  .where((b) => b.kind == BudgetKind.expense)
                  .fold<int>(0, (s, b) => s + b.targetMinorMain);
              final spent = m.expenseMinorMain;
              final left = (budgeted - spent).clamp(0, 1 << 62);
              final progress = budgeted > 0
                  ? (spent / budgeted).clamp(0.0, 1.0)
                  : 0.0;
              final today = DateTime.now();
              final daysRem = calendarDaysRemainingInViewedMonth(_month, today);
              final String? paceText = budgeted > 0 && daysRem > 0
                  ? l10n.budgetsSpendingPace(
                      '${_fmt(context, paceMinorPerDay(leftMinor: left, daysRemaining: daysRem), main)}${l10n.budgetsPaceSlashDay}',
                      l10n.budgetsDaysRemainingInMonth(daysRem),
                    )
                  : null;
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
                    children: [
                      Expanded(
                        child: _SmallBudgetCard(
                          title: l10n.budgetsBillsUtilities,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallBudgetCard(title: l10n.budgetsEarnings),
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
                    formatMoney: (x) => _fmt(context, x, main),
                    incomeSectionTitle: l10n.spendingIncome,
                    expenseSectionTitle: l10n.spendingExpense,
                  ),
                ],
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

class _SmallBudgetCard extends StatelessWidget {
  const _SmallBudgetCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(title, style: theme.textTheme.titleSmall),
      ),
    );
  }
}

class _CategoryBudgetList extends StatelessWidget {
  const _CategoryBudgetList({
    required this.month,
    required this.formatMoney,
    required this.incomeSectionTitle,
    required this.expenseSectionTitle,
  });

  final MonthlyTotals month;
  final String Function(int minor) formatMoney;
  final String incomeSectionTitle;
  final String expenseSectionTitle;

  @override
  Widget build(BuildContext context) {
    final incomeRows = <MapEntry<String, MonthlyBudgetEntry>>[];
    final expenseRows = <MapEntry<String, MonthlyBudgetEntry>>[];
    for (final e in month.budgets.entries) {
      if (e.value.kind == BudgetKind.income) {
        incomeRows.add(e);
      } else {
        expenseRows.add(e);
      }
    }
    final theme = Theme.of(context);
    return FinkoPaperCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (incomeRows.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Text(
                incomeSectionTitle,
                style: theme.textTheme.labelLarge,
              ),
            ),
            for (final e in incomeRows)
              _CategoryRow(
                categoryId: e.key,
                entry: e.value,
                spent: month.byCategoryMinorMain[e.key] ?? 0,
                formatMoney: formatMoney,
              ),
          ],
          if (expenseRows.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Text(
                expenseSectionTitle,
                style: theme.textTheme.labelLarge,
              ),
            ),
            for (final e in expenseRows)
              _CategoryRow(
                categoryId: e.key,
                entry: e.value,
                spent: month.byCategoryMinorMain[e.key] ?? 0,
                formatMoney: formatMoney,
              ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryId,
    required this.entry,
    required this.spent,
    required this.formatMoney,
  });

  final String categoryId;
  final MonthlyBudgetEntry entry;
  final int spent;
  final String Function(int minor) formatMoney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = entry.targetMinorMain;
    final ring = target > 0 ? (spent / target).clamp(0.0, 1.0) : 0.5;
    final left = (target - spent).clamp(0, 1 << 62);
    return ListTile(
      leading: FinkoCategoryAvatarRing(label: categoryId, progress: ring),
      title: Text(categoryId),
      subtitle: Text(formatMoney(left)),
      trailing: Text(formatMoney(spent), style: theme.textTheme.titleSmall),
    );
  }
}
