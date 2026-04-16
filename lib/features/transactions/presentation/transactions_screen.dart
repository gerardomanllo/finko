import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/transactions/finko_search_filter_bar.dart';
import '../../../widgets/transactions/finko_transaction_row_compact.dart';
import '../../shell/presentation/shell_drawer_controller.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _amount(BuildContext context, LedgerTransaction t) {
    final loc = Localizations.localeOf(context).toLanguageTag();
    final sign = t.direction == MoneyDirection.in_ ? '+' : '−';
    return '$sign ${formatMinorUnits(t.amountMinor, t.currency, loc)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(recentTransactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ShellDrawerController.open(context),
          tooltip: l10n.openShellMenu,
          icon: const Icon(Icons.settings_outlined),
        ),
        title: Text(l10n.transactionsTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FinkoSearchFilterBar(
              controller: _search,
              hintText: l10n.transactionsSearchHint,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              onFilterTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filters — coming soon')),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: async.when(
                data: (list) {
                  final filtered = _query.isEmpty
                      ? list
                      : list.where((t) {
                          final memo = (t.memo ?? '').toLowerCase();
                          final id = t.id.toLowerCase();
                          return memo.contains(_query) || id.contains(_query);
                        }).toList();
                  if (filtered.isEmpty) {
                    return Center(child: Text(l10n.emptyNoTransactions));
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      return FinkoTransactionRowCompact(
                        title: t.memo ?? t.type.wireName,
                        subtitle: t.transactionDate,
                        amountText: _amount(context, t),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
