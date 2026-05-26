import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/finko_category.dart';
import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/spending/fixed_variable_expense.dart';
import '../../../core/spending/spending_by_category_expense.dart';
import '../../../core/spending/spending_granularity.dart';
import '../../../core/spending/spending_labels.dart';
import '../../../core/spending/spending_period_descriptor.dart';
import '../../../core/spending/spending_period_filter.dart';
import '../../../core/spending/spending_period_generator.dart';
import '../../../core/spending/spending_transaction_aggregate.dart';
import '../../../core/ui/category_accent_color.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/accounts/finko_spending_income_fixed_variable_accordion.dart';
import '../../../widgets/charts/finko_donut_with_side_legend.dart';
import '../../../widgets/categories/finko_category_icon_avatar.dart';
import '../../../widgets/layout/pill_toggle_group.dart';
import '../../../widgets/metrics/finko_mini_income_expense_card.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';
import '../../../widgets/transactions/finko_transaction_row_compact.dart';
import '../../../widgets/transactions/ledger_transaction_editor_sheet.dart';
import '../../shell/presentation/shell_drawer_controller.dart';
import 'spending_providers.dart';

/// Outer radius minus [kDonutCenterSpaceRadius] → **very thin** ring (fl_chart).
const double kDonutSectionOuterRadius = 10;
const double kDonutCenterSpaceRadius = 75;

/// Vertical gap between spending **paper** sections so [scaffoldBackgroundColor]
/// (cloud) stays visible between cards.
const double kSpendingSectionCloudGap = 12;

class SpendingScreen extends ConsumerStatefulWidget {
  const SpendingScreen({super.key});

  @override
  ConsumerState<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends ConsumerState<SpendingScreen> {
  SpendingGranularity _granularity = SpendingGranularity.month;

  /// `null` → right-most card in the **filtered** strip.
  String? _selectedPeriodKey;

  final ScrollController _stripScrollController = ScrollController();

  /// After pill change, scroll strip to the right once the list has layout.
  bool _scrollStripAfterPillChange = false;

  @override
  void dispose() {
    _stripScrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollStripToEnd() {
    void tick() {
      if (!mounted) return;
      if (_stripScrollController.hasClients) {
        final p = _stripScrollController.position;
        p.jumpTo(p.maxScrollExtent);
        _scrollStripAfterPillChange = false;
        return;
      }
      if (_scrollStripAfterPillChange) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tick());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tick());
  }

  String _granularityLabel(AppLocalizations l10n, SpendingGranularity g) {
    return switch (g) {
      SpendingGranularity.week => l10n.spendingPeriodWeek,
      SpendingGranularity.month => l10n.spendingPeriodMonth,
      SpendingGranularity.quarter => l10n.spendingPeriodQuarter,
      SpendingGranularity.year => l10n.spendingPeriodYear,
    };
  }

  SpendingPeriodDescriptor _resolveSelected(
    List<SpendingPeriodDescriptor> filtered,
  ) {
    final i = filtered.indexWhere((e) => e.key == _selectedPeriodKey);
    final idx = i >= 0 ? i : filtered.length - 1;
    return filtered[idx];
  }

  List<LedgerTransaction> _txsInSelectedPeriod(
    List<LedgerTransaction> windowTxs,
    SpendingPeriodDescriptor selected,
  ) {
    return windowTxs
        .where(
          (t) =>
              t.transactionDate.compareTo(selected.startYyyyMmDd) >= 0 &&
              t.transactionDate.compareTo(selected.endYyyyMmDd) <= 0,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayYyyyMmDdProvider);
    final fullStrip = buildSpendingPeriodStrip(
      granularity: _granularity,
      todayYyyyMmDd: today,
    );

    final windowStart = fullStrip.isEmpty
        ? today
        : fullStrip.first.startYyyyMmDd;
    final windowEnd = fullStrip.isEmpty ? today : fullStrip.last.endYyyyMmDd;
    final windowAsync = ref.watch(
      transactionsForDateRangeStreamProvider((
        start: windowStart,
        end: windowEnd,
      )),
    );

    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final mainCurrency = profile?.mainCurrency ?? 'MXN';
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ShellDrawerController.open(context),
          tooltip: l10n.openShellMenu,
          icon: const Icon(Icons.settings_outlined),
        ),
        title: Text(l10n.spendingTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PillToggleGroup<SpendingGranularity>(
            values: SpendingGranularity.values,
            selected: _granularity,
            onChanged: (v) {
              setState(() {
                _granularity = v;
                _selectedPeriodKey = null;
                _scrollStripAfterPillChange = true;
              });
              _scheduleScrollStripToEnd();
            },
            labelOf: (g) => _granularityLabel(l10n, g),
          ),
          const SizedBox(height: 20),
          if (fullStrip.isEmpty)
            const SizedBox.shrink()
          else
            windowAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
              data: (windowTxs) {
                final filtered = periodsWithTransactions(fullStrip, windowTxs);
                if (filtered.isEmpty) {
                  _scrollStripAfterPillChange = false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.spendingStripEmpty,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final selected = _resolveSelected(filtered);
                final selectedIdx = filtered.indexWhere(
                  (e) => e.key == selected.key,
                );
                final selectedTxs = _txsInSelectedPeriod(windowTxs, selected);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FinkoPaperCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: SizedBox(
                        height: 148,
                        child: ListView.separated(
                          controller: _stripScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final d = filtered[i];
                            return _SpendingMiniCard(
                              descriptor: d,
                              isSelected: i == selectedIdx,
                              localeTag: localeTag,
                              onTap: () =>
                                  setState(() => _selectedPeriodKey = d.key),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: kSpendingSectionCloudGap),
                    _SpendingPeriodDetailColumn(
                      granularity: _granularity,
                      selected: selected,
                      selectedTxs: selectedTxs,
                      mainCurrency: mainCurrency,
                      localeTag: localeTag,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SpendingPeriodDetailColumn extends ConsumerWidget {
  const _SpendingPeriodDetailColumn({
    required this.granularity,
    required this.selected,
    required this.selectedTxs,
    required this.mainCurrency,
    required this.localeTag,
  });

  final SpendingGranularity granularity;
  final SpendingPeriodDescriptor selected;
  final List<LedgerTransaction> selectedTxs;
  final String mainCurrency;
  final String localeTag;

  String _format(BuildContext context, int minor, String code) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return formatMinorUnits(minor, code, locale);
  }

  static String _tx(BuildContext context, LedgerTransaction t) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return '−${formatMinorUnits(t.amountMinor, t.currency, locale)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mergedAsync = ref.watch(
      spendingMergedMonthlyRollupProvider(selected),
    );
    final flowAsync = ref.watch(spendingPeriodIncomeExpenseProvider(selected));
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final fixedCategoryIds = fixedExpenseCategoryIds(categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        flowAsync.when(
          data: (tuple) {
            return mergedAsync.when(
              data: (merged) {
                final useTxDonut = granularity == SpendingGranularity.week;
                final txRollup = aggregateSpendingTransactions(
                  selectedTxs,
                  mainCurrency: mainCurrency,
                );
                final totalExpense = useTxDonut
                    ? txRollup.totalExpenseMinorMain
                    : merged.expenseMinorMain;
                final fixedVar = useTxDonut
                    ? splitFixedVariableFromPositiveByCategory(
                        totalExpenseMinorMain: totalExpense,
                        byCategoryPositiveMinorMain:
                            txRollup.byCategoryMinorMain,
                        fixedCategoryIds: fixedCategoryIds,
                      )
                    : splitFixedVariableFromPositiveSlices(
                        totalExpenseMinorMain: totalExpense,
                        positiveExpenseByCategoryMinorMain:
                            positiveExpenseByCategoryId(
                              signedByCategoryMinorMain:
                                  merged.byCategoryMinorMain,
                              categories: categories,
                            ),
                        fixedCategoryIds: fixedCategoryIds,
                      );
                return FinkoSpendingIncomeFixedVariableAccordion(
                  incomeLabel: l10n.spendingIncome,
                  fixedLabel: l10n.spendingFixedExpenses,
                  variableLabel: l10n.spendingVariableExpenses,
                  incomeAmountText: _format(
                    context,
                    tuple.income,
                    mainCurrency,
                  ),
                  fixedAmountText: _format(
                    context,
                    fixedVar.fixedMinorMain,
                    mainCurrency,
                  ),
                  variableAmountText: _format(
                    context,
                    fixedVar.variableMinorMain,
                    mainCurrency,
                  ),
                );
              },
              loading: () => FinkoPaperCard(
                padding: const EdgeInsets.all(16),
                child: const LinearProgressIndicator(),
              ),
              error: (e, _) => FinkoPaperCard(
                padding: const EdgeInsets.all(16),
                child: Text('$e'),
              ),
            );
          },
          loading: () => FinkoPaperCard(
            padding: const EdgeInsets.all(16),
            child: const LinearProgressIndicator(),
          ),
          error: (e, _) => FinkoPaperCard(
            padding: const EdgeInsets.all(16),
            child: Text('$e'),
          ),
        ),
        const SizedBox(height: kSpendingSectionCloudGap),
        mergedAsync.when(
          data: (merged) {
            final useTxDonut = granularity == SpendingGranularity.week;
            final txRollup = aggregateSpendingTransactions(
              selectedTxs,
              mainCurrency: mainCurrency,
            );
            final totalExpense = useTxDonut
                ? txRollup.totalExpenseMinorMain
                : merged.expenseMinorMain;

            final positiveByCat = useTxDonut
                ? txRollup.byCategoryMinorMain
                : positiveExpenseByCategoryId(
                    signedByCategoryMinorMain: merged.byCategoryMinorMain,
                    categories: categories,
                  );

            final entries = positiveByCat.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final topEntries = entries.take(5).toList();

            FinkoCategory? catById(String id) {
              if (id.isEmpty) return null;
              for (final c in categories) {
                if (c.id == id) return c;
              }
              return null;
            }

            Color colorAt(String catId) {
              final c = catById(catId);
              return categoryAccentColor(
                theme.colorScheme,
                catId,
                colorArgb: c?.colorArgb,
              );
            }

            final sections = <PieChartSectionData>[];
            for (final e in topEntries) {
              sections.add(
                PieChartSectionData(
                  value: e.value.toDouble().clamp(1, 1e15),
                  color: colorAt(e.key),
                  radius: kDonutSectionOuterRadius,
                  title: '',
                ),
              );
            }
            if (sections.isEmpty) {
              sections.add(
                PieChartSectionData(
                  value: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  radius: kDonutSectionOuterRadius,
                  title: '',
                ),
              );
            }

            final legendRows = <FinkoDonutLegendRow>[];
            for (final e in topEntries) {
              final name = e.key.isEmpty
                  ? l10n.spendingUncategorized
                  : (catById(e.key)?.name ?? e.key);
              final pct = totalExpense > 0
                  ? '${((e.value / totalExpense) * 100).round()}%'
                  : null;
              legendRows.add(
                FinkoDonutLegendRow(
                  color: colorAt(e.key),
                  title: name,
                  valueText: _format(context, e.value, mainCurrency),
                  percentText: pct,
                ),
              );
            }

            final periodLabel = spendingPeriodCardLabel(localeTag, selected);

            return FinkoPaperCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: FinkoDonutWithSideLegend(
                sections: sections,
                centerTitle: l10n.spendingTotalSpendIn,
                centerSubtitle: periodLabel,
                centerTotal: _format(context, totalExpense, mainCurrency),
                legendRows: legendRows,
                centerSpaceRadius: kDonutCenterSpaceRadius,
                sectionsSpace: 0,
              ),
            );
          },
          loading: () => FinkoPaperCard(
            padding: const EdgeInsets.all(24),
            child: const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => FinkoPaperCard(
            padding: const EdgeInsets.all(16),
            child: Text('$e'),
          ),
        ),
        const SizedBox(height: kSpendingSectionCloudGap),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.spendingTopTransactions,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final rollup = aggregateSpendingTransactions(
                  selectedTxs,
                  mainCurrency: mainCurrency,
                );
                final catById = <String, FinkoCategory>{
                  for (final c in categories) c.id: c,
                };
                final top = rollup.topOutflows;
                if (top.isEmpty) {
                  return FinkoPaperCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      l10n.emptyNoTransactions,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                return FinkoPaperCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final t in top)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: FinkoTransactionRowCompact(
                            leading: ledgerTransactionCategoryLeading(
                              t,
                              catById,
                            ),
                            title: t.memo ?? t.type.wireName,
                            subtitle: t.transactionDate,
                            amountText: _tx(context, t),
                            onTap: () => LedgerTransactionEditorSheet.show(
                              context,
                              transaction: t,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SpendingMiniCard extends ConsumerWidget {
  const _SpendingMiniCard({
    required this.descriptor,
    required this.isSelected,
    required this.localeTag,
    required this.onTap,
  });

  final SpendingPeriodDescriptor descriptor;
  final bool isSelected;
  final String localeTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(spendingPeriodIncomeExpenseProvider(descriptor));
    return flow.when(
      data: (tuple) {
        final maxBar =
            (tuple.income > tuple.expense ? tuple.income : tuple.expense).clamp(
              1,
              1 << 62,
            );
        final incF = (tuple.income / maxBar).clamp(0.05, 1.0);
        final expF = (tuple.expense / maxBar).clamp(0.05, 1.0);
        return FinkoMiniIncomeExpenseCard(
          bottomLabel: spendingPeriodCardLabel(localeTag, descriptor),
          incomeFraction: incF,
          expenseFraction: expF,
          isSelected: isSelected,
          onTap: onTap,
        );
      },
      loading: () => FinkoMiniIncomeExpenseCard(
        bottomLabel: spendingPeriodCardLabel(localeTag, descriptor),
        incomeFraction: 0.35,
        expenseFraction: 0.45,
        isSelected: isSelected,
        onTap: onTap,
      ),
      error: (_, _) => FinkoMiniIncomeExpenseCard(
        bottomLabel: spendingPeriodCardLabel(localeTag, descriptor),
        incomeFraction: 0.05,
        expenseFraction: 0.05,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }
}
