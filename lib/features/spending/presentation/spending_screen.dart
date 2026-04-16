import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/accounts/finko_income_expense_accordion.dart';
import '../../../widgets/charts/finko_donut_ring_chart.dart';
import '../../../widgets/layout/pill_toggle_group.dart';
import '../../../widgets/metrics/finko_mini_income_expense_card.dart';
import '../../../widgets/transactions/finko_transaction_row_compact.dart';

/// Spending analysis — period pills, mini cards, donut, accordion, top tx.
enum SpendingPeriod { week, month, quarter, year }

class SpendingScreen extends ConsumerStatefulWidget {
  const SpendingScreen({super.key});

  @override
  ConsumerState<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends ConsumerState<SpendingScreen> {
  SpendingPeriod _period = SpendingPeriod.month;

  String _periodLabel(AppLocalizations l10n, SpendingPeriod p) {
    return switch (p) {
      SpendingPeriod.week => l10n.spendingPeriodWeek,
      SpendingPeriod.month => l10n.spendingPeriodMonth,
      SpendingPeriod.quarter => l10n.spendingPeriodQuarter,
      SpendingPeriod.year => l10n.spendingPeriodYear,
    };
  }

  String _format(BuildContext context, int minor, String code) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return formatMinorUnits(minor, code, locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final monthAsync = ref.watch(currentMonthTotalsStreamProvider);
    final recentAsync = ref.watch(recentTransactionsStreamProvider);

    final mainCurrency = 'MXN';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.spendingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PillToggleGroup<SpendingPeriod>(
            values: SpendingPeriod.values,
            selected: _period,
            onChanged: (v) => setState(() => _period = v),
            labelOf: (p) => _periodLabel(l10n, p),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final label = switch (i) {
                  0 => 'W1',
                  1 => 'W2',
                  2 => 'W3',
                  3 => 'W4',
                  4 => 'W5',
                  _ => 'W6',
                };
                return FinkoMiniIncomeExpenseCard(
                  bottomLabel: _period == SpendingPeriod.month
                      ? _periodLabel(l10n, SpendingPeriod.month)
                      : label,
                  incomeFraction: 0.35 + (i % 4) * 0.1,
                  expenseFraction: 0.45 + (i % 3) * 0.08,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          monthAsync.when(
            data: (m) {
              final income = m?.incomeMinorMain ?? 0;
              final expense = m?.expenseMinorMain ?? 0;
              return FinkoIncomeExpenseAccordion(
                incomeLabel: l10n.spendingIncome,
                expenseLabel: l10n.spendingExpense,
                incomeAmountText: _format(context, income, mainCurrency),
                expenseAmountText: _format(context, expense, mainCurrency),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 24),
          Center(
            child: monthAsync.when(
              data: (m) {
                final total = m?.expenseMinorMain ?? 0;
                final byCat = m?.byCategoryMinorMain ?? {};
                final entries = byCat.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final palette = <Color>[
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ];
                final sections = <PieChartSectionData>[];
                var i = 0;
                for (final e in entries.take(5)) {
                  sections.add(
                    PieChartSectionData(
                      value: e.value.toDouble().clamp(1, 1e15),
                      color: palette[i % palette.length],
                      radius: 28,
                      title: '',
                    ),
                  );
                  i++;
                }
                if (sections.isEmpty) {
                  sections.add(
                    PieChartSectionData(
                      value: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      radius: 28,
                      title: '',
                    ),
                  );
                }
                return FinkoDonutRingChart(
                  sections: sections,
                  centerTitle: l10n.spendingTotalSpend,
                  centerTotal: _format(context, total, mainCurrency),
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.spendingInPeriod(_periodLabel(l10n, _period)),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.spendingTopTransactions,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          recentAsync.when(
            data: (list) {
              final top = list
                  .where((t) => t.direction == MoneyDirection.out_)
                  .take(4)
                  .toList();
              if (top.isEmpty) {
                return Text(l10n.emptyNoTransactions);
              }
              return Column(
                children: [
                  for (final t in top)
                    FinkoTransactionRowCompact(
                      title: t.memo ?? t.type.wireName,
                      subtitle: t.transactionDate,
                      amountText: _tx(context, t),
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

  static String _tx(BuildContext context, LedgerTransaction t) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return '− ${formatMinorUnits(t.amountMinor, t.currency, locale)}';
  }
}
