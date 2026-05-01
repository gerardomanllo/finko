import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/finko_category.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/recurring_rule.dart';
import '../../../core/data/models/upcoming_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/datetime/user_calendar_date.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/refresh/ledger_aware_app_refresh.dart';
import '../../../features/onboarding/presentation/onboarding_category_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/calendar/finko_two_week_calendar.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';
import '../../../widgets/transactions/finko_transaction_row_compact.dart';
import '../../shell/presentation/shell_drawer_controller.dart';

DateTime _mondayOfCalendarDay(DateTime dateOnly) {
  final local = DateTime(dateOnly.year, dateOnly.month, dateOnly.day);
  return local.subtract(Duration(days: local.weekday - DateTime.monday));
}

({String amountText, String? secondaryAmountText}) _upcomingRowAmounts(
  BuildContext context,
  UpcomingTransaction u,
  String mainCurrency,
) {
  final loc = Localizations.localeOf(context).toLanguageTag();
  final sign = u.direction == MoneyDirection.in_ ? '+' : '−';
  if (u.amountMinorMain != null && u.currency != mainCurrency) {
    return (
      amountText:
          '$sign${formatMinorUnits(u.amountMinorMain!, mainCurrency, loc)}',
      secondaryAmountText: formatMinorUnitsWithCode(
        u.amountMinor,
        u.currency,
        loc,
      ),
    );
  }
  if (u.currency == mainCurrency) {
    return (
      amountText: '$sign${formatMinorUnits(u.amountMinor, u.currency, loc)}',
      secondaryAmountText: null,
    );
  }
  return (
    amountText:
        '$sign${formatMinorUnitsWithCode(u.amountMinor, u.currency, loc)}',
    secondaryAmountText: null,
  );
}

String _rowTitle(
  UpcomingTransaction u,
  Map<String, RecurringRule> ruleById,
  Map<String, FinkoCategory> catById,
) {
  final memo = u.memo?.trim();
  if (memo != null && memo.isNotEmpty) return memo;
  final rid = u.recurringRuleId;
  if (rid != null) {
    final rule = ruleById[rid];
    if (rule != null && rule.name.trim().isNotEmpty) return rule.name;
  }
  final cid = u.categoryId;
  if (cid != null) {
    final c = catById[cid];
    if (c != null) return c.name;
  }
  return u.kind.wireName;
}

Widget? _rowLeading(UpcomingTransaction u, Map<String, FinkoCategory> catById) {
  final cid = u.categoryId;
  if (cid == null) return null;
  final c = catById[cid];
  if (c == null) return null;
  return Icon(onboardingIconForKey(c.iconKey));
}

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(ledgerAwareAppRefreshProvider).runPullToRefresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final upcomingAsync = ref.watch(recurringMergedUpcomingProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final rulesAsync = ref.watch(recurringRulesStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final mainCurrency =
        profileAsync.valueOrNull?.mainCurrency ??
        accountsAsync.valueOrNull?.firstOrNull?.currency ??
        'MXN';
    final todayYmd = ref.watch(todayYyyyMmDdProvider);
    final monday = _mondayOfCalendarDay(parseYyyyMmDdLocal(todayYmd));

    final ruleById = <String, RecurringRule>{
      for (final r in rulesAsync.valueOrNull ?? const <RecurringRule>[])
        r.id: r,
    };
    final catById = <String, FinkoCategory>{
      for (final c in categoriesAsync.valueOrNull ?? const <FinkoCategory>[])
        c.id: c,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ShellDrawerController.open(context),
          tooltip: l10n.openShellMenu,
          icon: const Icon(Icons.settings_outlined),
        ),
        title: Text(l10n.recurringTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (upcomingAsync.hasError ||
                categoriesAsync.hasError ||
                rulesAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            upcomingAsync.error?.toString() ??
                                categoriesAsync.error?.toString() ??
                                rulesAsync.error?.toString() ??
                                'Error',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.invalidate(upcomingTransactionsStreamProvider);
                            ref.invalidate(
                              futureDatedLedgerTransactionsStreamProvider,
                            );
                            ref.invalidate(
                              ledgerFromTodayForUpcomingMergeStreamProvider,
                            );
                            ref.invalidate(recurringMergedUpcomingProvider);
                            ref.invalidate(categoriesStreamProvider);
                            ref.invalidate(recurringRulesStreamProvider);
                          },
                          child: Text(l10n.actionRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Text(
              l10n.recurringComingUp,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            upcomingAsync.when(
              data: (list) {
                final marked = <String>{};
                final income = <String>{};
                for (final u in list) {
                  final days = daysBetweenYyyyMmDd(todayYmd, u.transactionDate);
                  if (days >= 0 && days < 14) {
                    marked.add(u.transactionDate);
                    if (u.direction == MoneyDirection.in_) {
                      income.add(u.transactionDate);
                    }
                  }
                }
                return FinkoTwoWeekCalendar(
                  weekStart: monday,
                  markedDays: marked,
                  incomeDays: income,
                  thisWeekLabel: l10n.recurringThisWeek,
                  nextWeekLabel: l10n.recurringNextWeek,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (Object e, StackTrace stack) => Text('$e'),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.recurringDueSoon,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            upcomingAsync.when(
              data: (list) => _DueList(
                list: list,
                test: (u) {
                  final d = daysBetweenYyyyMmDd(todayYmd, u.transactionDate);
                  return d >= 0 && d <= 7;
                },
                mainCurrency: mainCurrency,
                ruleById: ruleById,
                catById: catById,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (Object e, StackTrace stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.recurringComingLater,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            upcomingAsync.when(
              data: (list) => _DueList(
                list: list,
                test: (u) {
                  final d = daysBetweenYyyyMmDd(todayYmd, u.transactionDate);
                  return d >= 8 && d <= 15;
                },
                mainCurrency: mainCurrency,
                ruleById: ruleById,
                catById: catById,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (Object e, StackTrace stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueList extends StatelessWidget {
  const _DueList({
    required this.list,
    required this.test,
    required this.mainCurrency,
    required this.ruleById,
    required this.catById,
  });

  final List<UpcomingTransaction> list;
  final bool Function(UpcomingTransaction u) test;
  final String mainCurrency;
  final Map<String, RecurringRule> ruleById;
  final Map<String, FinkoCategory> catById;

  @override
  Widget build(BuildContext context) {
    final filtered = list.where(test).toList()
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    if (filtered.isEmpty) {
      return const Text('—');
    }
    return FinkoPaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ...filtered.map((u) {
            final row = _upcomingRowAmounts(context, u, mainCurrency);
            return FinkoTransactionRowCompact(
              title: _rowTitle(u, ruleById, catById),
              subtitle: u.transactionDate,
              amountText: row.amountText,
              secondaryAmountText: row.secondaryAmountText,
              leading: _rowLeading(u, catById),
            );
          }),
        ],
      ),
    );
  }
}
