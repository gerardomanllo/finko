import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/app_environment.dart';
import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/models/finko_account.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/models/monthly_totals.dart';
import '../../../core/data/models/upcoming_transaction.dart';
import '../../../core/data/providers/dashboard_ui_stub_provider.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/locale/app_environment_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/accounts/finko_cash_flow_accounts_accordion.dart';
import '../../../widgets/budgets/finko_monthly_budget_teaser.dart';
import '../../../widgets/metrics/finko_metric_carousel_card.dart';
import '../../../widgets/metrics/finko_net_worth_sparkline.dart';
import '../../../widgets/metrics/finko_two_metric_carousel.dart';
import '../../../widgets/transactions/finko_paper_see_more_list.dart';
import '../../../widgets/transactions/finko_transaction_row_compact.dart';
import '../../../widgets/transactions/finko_upcoming_transaction_strip.dart';

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
      FinkoAccountType.checking => l10n.accountTypeChecking,
      FinkoAccountType.creditCard => l10n.accountTypeCreditCard,
      FinkoAccountType.savings => l10n.accountTypeSavings,
      FinkoAccountType.investment => l10n.accountTypeInvestment,
      FinkoAccountType.loan => l10n.loansMortgageSectionTitle,
      FinkoAccountType.mortgage => l10n.loansMortgageSectionTitle,
    };
  }

  static int _netCashMinor(Iterable<FinkoAccount> accounts) {
    return accounts
        .where((a) => a.includeInNetCash)
        .fold<int>(0, (s, a) => s + (a.balanceMinorMain ?? a.balanceMinor));
  }

  static String _daysUntilLabel(AppLocalizations l10n, String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return '';
    final target = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = target.difference(today).inDays;
    if (d <= 0) return l10n.upcomingToday;
    if (d == 1) return l10n.upcomingTomorrow;
    return l10n.upcomingInDays(d);
  }

  static int _totalExpenseBudgetMinor(MonthlyTotals? m) {
    if (m == null) return 0;
    var sum = 0;
    for (final e in m.budgets.values) {
      if (e.kind == BudgetKind.expense) {
        sum += e.targetMinorMain;
      }
    }
    return sum;
  }

  static List<({String label, double ringProgress})> _topCategoryRings(
    MonthlyTotals? m,
  ) {
    if (m == null) return [];
    final sorted = m.byCategoryMinorMain.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    if (top.isEmpty) return [];
    final maxSpend = top.first.value;
    final out = <({String label, double ringProgress})>[];
    for (final e in top) {
      final budget = m.budgets[e.key];
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
    final env = ref.watch(appEnvironmentProvider);
    final envLabel = env == AppEnvironment.dev ? 'DEV' : 'PROD';
    final user = ref.watch(authStateProvider).valueOrNull;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final monthAsync = ref.watch(currentMonthTotalsStreamProvider);
    final recentAsync = ref.watch(recentTransactionsStreamProvider);
    final upcomingAsync = ref.watch(upcomingTransactionsStreamProvider);
    final sparkline = ref.watch(netWorthSparklineStubProvider);

    final locale = Localizations.localeOf(context).toString();
    final dateLine = DateFormat('E, MMM d', locale).format(DateTime.now());

    final mainCurrency = accountsAsync.valueOrNull?.isNotEmpty == true
        ? accountsAsync.valueOrNull!.first.currency
        : 'MXN';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text(
            l10n.environmentBanner(envLabel),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.dashboardSignedInAs(user!.email!),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            dateLine,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.dashboardHeadline, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 20),
          FinkoTwoMetricCarousel(
            first: FinkoMetricCarouselCard(
              label: l10n.metricNetWorth,
              valueText: _formatMoney(
                context,
                sparkline.last.toInt(),
                mainCurrency,
              ),
              deltaText: l10n.metricDeltaStubUp,
              chart: FinkoNetWorthSparkline(values: sparkline),
              onTap: () => context.push('/accounts'),
            ),
            second: FinkoMetricCarouselCard(
              label: l10n.metricMonthlyExpense,
              valueText: monthAsync.maybeWhen(
                data: (m) => m == null
                    ? '—'
                    : _formatMoney(context, m.expenseMinorMain, mainCurrency),
                orElse: () => '—',
              ),
              deltaText: l10n.metricDeltaStubDown,
              chart: const Center(child: Icon(Icons.bar_chart, size: 48)),
              onTap: () => context.go('/spending'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.dashboardAccountsHeading,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) {
                return Text(l10n.emptyNoAccounts);
              }
              return FinkoCashFlowAccountsAccordion(
                accounts: accounts,
                netCashMinorMain: _netCashMinor(accounts),
                formatMoney: (minor, code) =>
                    _formatMoney(context, minor, code),
                accountTypeLabel: (t) => _accountTypeLabel(l10n, t),
                netCashTitle: l10n.netCashLabel,
                otherLiabilitiesTitle: l10n.loansMortgageSectionTitle,
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
              final sorted = [
                ...list,
              ]..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
              return SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sorted.length.clamp(0, 20),
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final u = sorted[i];
                    return FinkoUpcomingTransactionCard(
                      title: u.memo ?? u.kind.wireName,
                      amountText: _txAmount(context, u),
                      footerText: _daysUntilLabel(l10n, u.transactionDate),
                    );
                  },
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 24),
          Text(l10n.dashboardRecentHeading, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          recentAsync.when(
            data: (list) {
              final recent = list.take(5).toList();
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
                      amountText: _ledgerAmount(context, t),
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
              final budgetTotal = _totalExpenseBudgetMinor(m);
              final spent = m.expenseMinorMain;
              final left = (budgetTotal - spent).clamp(0, 1 << 62);
              final progress = budgetTotal > 0
                  ? (spent / budgetTotal).clamp(0.0, 1.0)
                  : 0.0;
              return FinkoMonthlyBudgetTeaser(
                title: l10n.thisMonthsBudget,
                leftForSpendingLabel: l10n.leftForSpending,
                leftForSpendingText: _formatMoney(context, left, mainCurrency),
                progress: progress,
                categoryRings: _topCategoryRings(m),
                onTap: () => context.push('/budgets'),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static String _ledgerAmount(BuildContext context, LedgerTransaction t) {
    final sign = t.direction == MoneyDirection.in_ ? '+' : '−';
    final amt = _formatMoney(context, t.amountMinor, t.currency);
    return '$sign $amt';
  }

  static String _txAmount(BuildContext context, UpcomingTransaction u) {
    final sign = u.direction == MoneyDirection.in_ ? '+' : '−';
    final amt = _formatMoney(context, u.amountMinor, u.currency);
    return '$sign $amt';
  }
}
