import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/budget/monthly_budget_rollup.dart';
import '../../../core/data/models/finko_account.dart';
import '../../../core/data/models/finko_account_kind.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/models/monthly_totals.dart';
import '../../../core/data/models/upcoming_transaction.dart';
import '../../../core/data/monthly_totals_as_of_date.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/refresh/ledger_aware_app_refresh.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/accounts/finko_cash_flow_accounts_accordion.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';
import '../../../widgets/budgets/finko_monthly_budget_teaser.dart';
import '../../../widgets/metrics/finko_metric_carousel_card.dart';
import '../../../widgets/metrics/finko_net_worth_sparkline.dart';
import '../../../widgets/metrics/finko_two_metric_carousel.dart';
import '../../../widgets/transactions/finko_paper_see_more_list.dart';
import '../../../widgets/transactions/finko_transaction_row_compact.dart';
import '../../../widgets/transactions/ledger_transaction_editor_sheet.dart';
import '../../../widgets/transactions/finko_upcoming_transaction_strip.dart';
import '../../shell/presentation/shell_drawer_controller.dart';

/// Horizontal inset for dashboard copy and lists (carousel is full-bleed).
const EdgeInsets _kDashboardHorizontalPadding = EdgeInsets.symmetric(
  horizontal: 20,
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static String _formatMoney(
    BuildContext context,
    int minor,
    String currencyCode,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return formatMinorUnits(minor, currencyCode, locale);
  }

  static String _accountTypeLabel(AppLocalizations l10n, FinkoAccountType t) {
    return switch (t) {
      FinkoAccountType.cash => l10n.accountTypeCash,
      FinkoAccountType.checking => l10n.accountTypeChecking,
      FinkoAccountType.creditCard => l10n.accountTypeCreditCard,
      FinkoAccountType.savings => l10n.accountTypeSavings,
      FinkoAccountType.investment => l10n.accountTypeInvestment,
      FinkoAccountType.loan => l10n.loansMortgageSectionTitle,
      FinkoAccountType.mortgage => l10n.loansMortgageSectionTitle,
    };
  }

  static String _daysUntilLabel(
    AppLocalizations l10n,
    String yyyyMmDd,
    String todayYyyyMmDd,
  ) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return '';
    final target = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final tp = todayYyyyMmDd.split('-');
    if (tp.length != 3) return '';
    final today = DateTime(
      int.parse(tp[0]),
      int.parse(tp[1]),
      int.parse(tp[2]),
    );
    final d = target.difference(today).inDays;
    if (d <= 0) return l10n.upcomingToday;
    if (d == 1) return l10n.upcomingTomorrow;
    return l10n.upcomingInDays(d);
  }

  static List<({String label, double ringProgress})> _topCategoryRings(
    MonthlyTotals? m,
    Map<String, MonthlyBudgetEntry> budgets,
    String throughYyyyMmDd,
  ) {
    if (m == null) return [];
    final byCat = byCategoryMinorMainThroughDate(m, throughYyyyMmDd);
    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    if (top.isEmpty) return [];
    final maxSpend = top.first.value;
    final out = <({String label, double ringProgress})>[];
    for (final e in top) {
      final budget = budgets[e.key];
      final spent = e.value;
      double ring;
      if (budget != null && budget.targetMinorMain > 0) {
        ring = (spent / budget.targetMinorMain).clamp(0.0, 1.0);
      } else if (maxSpend > 0) {
        ring = (spent / maxSpend).clamp(0.0, 1.0);
      } else {
        ring = 0.5;
      }
      final label = e.key.length > 8 ? e.key.substring(0, 8) : e.key;
      out.add((label: label, ringProgress: ring));
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final accountsAsync = ref.watch(accountsStreamProvider);
    final userProfileAsync = ref.watch(userProfileStreamProvider);
    final monthAsync = ref.watch(
      monthlyTotalsForMonthStreamProvider(
        ref.watch(dashboardYearMonthProvider),
      ),
    );
    final recentAsync = ref.watch(recentTransactionsStreamProvider);
    final upcomingAsync = ref.watch(dashboardUpcomingStripProvider);
    final todayKey = ref.watch(todayYyyyMmDdProvider);
    final sparkline = ref.watch(netWorthSparklineSeriesProvider);

    final locale = Localizations.localeOf(context).toString();
    final dateLine = DateFormat('E, MMM d', locale).format(DateTime.now());

    final mainCurrency =
        userProfileAsync.valueOrNull?.mainCurrency ??
        accountsAsync.valueOrNull?.firstOrNull?.currency ??
        'MXN';
    final accounts = accountsAsync.valueOrNull ?? const <FinkoAccount>[];
    final netWorthFromAccounts = netWorthFromAccountsMinor(accounts);
    final hasSparklinePoints = sparkline.any((point) => point != 0);
    final netWorthDisplayMinor = hasSparklinePoints
        ? sparkline.last.toInt()
        : netWorthFromAccounts;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => ShellDrawerController.open(context),
          tooltip: l10n.openShellMenu,
          icon: const Icon(Icons.settings_outlined),
        ),
        title: Text(
          dateLine,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: const [
          // Balance default leading width so the title stays visually centered.
          SizedBox(width: 56),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(ledgerAwareAppRefreshProvider).runPullToRefresh(ref);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            FinkoTwoMetricCarousel(
              first: FinkoMetricCarouselCard(
                label: l10n.metricNetWorth,
                valueText: _formatMoney(
                  context,
                  netWorthDisplayMinor,
                  mainCurrency,
                ),
                deltaText: l10n.metricDeltaStubUp,
                expandChartVertically: true,
                chart: FinkoNetWorthSparkline(values: sparkline),
                footer: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.metricNetWorthSeeAccountsFooter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onTap: () => context.push('/accounts'),
              ),
              second: FinkoMetricCarouselCard(
                label: l10n.metricMonthlyExpense,
                valueText: monthAsync.maybeWhen(
                  data: (m) => m == null
                      ? '—'
                      : _formatMoney(
                          context,
                          expenseMinorMainThroughDate(m, todayKey),
                          mainCurrency,
                        ),
                  orElse: () => '—',
                ),
                deltaText: l10n.metricDeltaStubDown,
                expandChartVertically: true,
                chart: const Center(child: Icon(Icons.bar_chart, size: 48)),
                onTap: () => context.go('/spending'),
              ),
            ),
            Padding(
              padding: _kDashboardHorizontalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    l10n.dashboardAccountsHeading,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  accountsAsync.when(
                    data: (accounts) {
                      return FinkoCashFlowAccountsAccordion(
                        accounts: accounts,
                        mainCurrencyCode: mainCurrency,
                        netCashMinorMain: netCashFromAccountsMinor(accounts),
                        formatMoney: (minor, code) =>
                            _formatMoney(context, minor, code),
                        formatMoneyWithCode: (minor, code) {
                          final locale = Localizations.localeOf(
                            context,
                          ).toLanguageTag();
                          return formatMinorUnitsWithCode(minor, code, locale);
                        },
                        accountTypeLabel: (t) => _accountTypeLabel(l10n, t),
                        netCashTitle: l10n.netCashLabel,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.dashboardUpcomingHeading,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  upcomingAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return Text(l10n.emptyNoUpcoming);
                      }
                      return FinkoPaperCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: SizedBox(
                          height: 168,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: list.length.clamp(0, 20),
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final u = list[i];
                              return FinkoUpcomingTransactionCard(
                                title: u.memo ?? u.kind.wireName,
                                amountText: _upcomingAmount(
                                  context,
                                  u,
                                  mainCurrency,
                                ),
                                secondaryAmountText: _upcomingSecondaryAmount(
                                  context,
                                  u,
                                  mainCurrency,
                                ),
                                footerText: _daysUntilLabel(
                                  l10n,
                                  u.transactionDate,
                                  todayKey,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.dashboardRecentHeading,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  recentAsync.when(
                    data: (list) {
                      final recent = list;
                      if (recent.isEmpty) {
                        return Text(l10n.emptyNoTransactions);
                      }
                      return FinkoPaperSeeMoreList(
                        seeMoreLabel: l10n.seeMore,
                        onSeeMore: () => context.go('/transactions'),
                        children: [
                          for (final t in recent)
                            FinkoTransactionRowCompact(
                              title: t.memo ?? t.type.wireName,
                              subtitle: t.transactionDate,
                              amountText: _ledgerAmount(
                                context,
                                t,
                                mainCurrency,
                              ),
                              secondaryAmountText: _ledgerSecondaryAmount(
                                context,
                                t,
                                mainCurrency,
                              ),
                              onTap: () => LedgerTransactionEditorSheet.show(
                                context,
                                transaction: t,
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                  ),
                  const SizedBox(height: 24),
                  monthAsync.when(
                    data: (m) {
                      if (m == null) {
                        return Text(l10n.emptyNoMonthlyTotals);
                      }
                      final budgets =
                          userProfileAsync.valueOrNull?.budgets ??
                          const <String, MonthlyBudgetEntry>{};
                      final budgetTotal = totalExpenseBudgetMinor(budgets);
                      final spent = expenseMinorMainThroughDate(m, todayKey);
                      final left = (budgetTotal - spent).clamp(0, 1 << 62);
                      final progress = budgetTotal > 0
                          ? (spent / budgetTotal).clamp(0.0, 1.0)
                          : 0.0;
                      return FinkoMonthlyBudgetTeaser(
                        title: l10n.thisMonthsBudget,
                        leftForSpendingLabel: l10n.leftForSpending,
                        leftForSpendingText: _formatMoney(
                          context,
                          left,
                          mainCurrency,
                        ),
                        progress: progress,
                        categoryRings: _topCategoryRings(m, budgets, todayKey),
                        onTap: () => context.push('/budgets'),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _ledgerAmount(
    BuildContext context,
    LedgerTransaction t,
    String mainCurrency,
  ) {
    final sign = t.direction == MoneyDirection.in_ ? '+' : '−';
    final amt = _formatMoney(
      context,
      t.amountMinorMain ?? t.amountMinor,
      t.amountMinorMain != null ? mainCurrency : t.currency,
    );
    return '$sign$amt';
  }

  static String? _ledgerSecondaryAmount(
    BuildContext context,
    LedgerTransaction t,
    String mainCurrency,
  ) {
    if (t.currency == mainCurrency || t.amountMinorMain == null) {
      return null;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return formatMinorUnitsWithCode(t.amountMinor, t.currency, locale);
  }

  static String _upcomingAmount(
    BuildContext context,
    UpcomingTransaction u,
    String mainCurrency,
  ) {
    final sign = u.direction == MoneyDirection.in_ ? '+' : '−';
    final amt = _formatMoney(
      context,
      u.amountMinorMain ?? u.amountMinor,
      u.amountMinorMain != null ? mainCurrency : u.currency,
    );
    return '$sign$amt';
  }

  static String? _upcomingSecondaryAmount(
    BuildContext context,
    UpcomingTransaction u,
    String mainCurrency,
  ) {
    if (u.currency == mainCurrency || u.amountMinorMain == null) {
      return null;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return formatMinorUnitsWithCode(u.amountMinor, u.currency, locale);
  }
}
