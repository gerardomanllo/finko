import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/upcoming_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/calendar/finko_two_week_calendar.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';
import '../../../widgets/transactions/finko_transaction_row_compact.dart';
import '../../shell/presentation/shell_drawer_controller.dart';

DateTime _mondayOf(DateTime d) {
  final local = DateTime(d.year, d.month, d.day);
  return local.subtract(Duration(days: local.weekday - DateTime.monday));
}

int _daysFromToday(String yyyyMmDd) {
  final parts = yyyyMmDd.split('-');
  if (parts.length != 3) return 999;
  final t = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return t.difference(today).inDays;
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
          '$sign ${formatMinorUnits(u.amountMinorMain!, mainCurrency, loc)}',
      secondaryAmountText: formatMinorUnitsWithCode(
        u.amountMinor,
        u.currency,
        loc,
      ),
    );
  }
  if (u.currency == mainCurrency) {
    return (
      amountText: '$sign ${formatMinorUnits(u.amountMinor, u.currency, loc)}',
      secondaryAmountText: null,
    );
  }
  return (
    amountText:
        '$sign ${formatMinorUnitsWithCode(u.amountMinor, u.currency, loc)}',
    secondaryAmountText: null,
  );
}

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final upcomingAsync = ref.watch(upcomingTransactionsStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final mainCurrency =
        profileAsync.valueOrNull?.mainCurrency ??
        accountsAsync.valueOrNull?.firstOrNull?.currency ??
        'MXN';
    final monday = _mondayOf(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ShellDrawerController.open(context),
          tooltip: l10n.openShellMenu,
          icon: const Icon(Icons.settings_outlined),
        ),
        title: Text(l10n.recurringTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                final days = _daysFromToday(u.transactionDate);
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
                final d = _daysFromToday(u.transactionDate);
                return d >= 0 && d <= 7;
              },
              mainCurrency: mainCurrency,
            ),
            loading: () => const SizedBox.shrink(),
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
                final d = _daysFromToday(u.transactionDate);
                return d >= 8 && d <= 15;
              },
              mainCurrency: mainCurrency,
            ),
            loading: () => const SizedBox.shrink(),
            error: (Object e, StackTrace stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DueList extends StatelessWidget {
  const _DueList({
    required this.list,
    required this.test,
    required this.mainCurrency,
  });

  final List<UpcomingTransaction> list;
  final bool Function(UpcomingTransaction u) test;
  final String mainCurrency;

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
              title: u.memo ?? u.kind.wireName,
              subtitle: u.transactionDate,
              amountText: row.amountText,
              secondaryAmountText: row.secondaryAmountText,
            );
          }),
        ],
      ),
    );
  }
}
