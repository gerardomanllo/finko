import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';
import '../../../widgets/transactions/finko_search_filter_bar.dart';
import '../../../widgets/transactions/finko_transaction_row_compact.dart';
import '../../../widgets/transactions/ledger_transaction_editor_sheet.dart';
import '../../../widgets/transactions/transaction_kind_filter_sheet.dart';
import '../../shell/presentation/shell_drawer_controller.dart';
import '../application/transactions_list_notifier.dart';
import '../application/transactions_list_state.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    ref
        .read(transactionsListNotifierProvider.notifier)
        .onScroll(_scroll.position);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  String _filterTooltip(AppLocalizations l10n, TransactionsListState s) {
    switch (s.filterIndex % 4) {
      case 0:
        return l10n.transactionsFilterAll;
      case 1:
        return l10n.transactionsFilterStandard;
      case 2:
        return l10n.transactionsFilterTransfer;
      case 3:
        return l10n.transactionsFilterAdjustment;
      default:
        return l10n.transactionsFilterAll;
    }
  }

  Future<void> _openFilterSheet() async {
    final notifier = ref.read(transactionsListNotifierProvider.notifier);
    final current = ref.read(transactionsListNotifierProvider).filterIndex;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => TransactionKindFilterSheet(
        selectedIndex: current,
        onSelected: (index) {
          notifier.setFilterIndex(index);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Widget? _historyBelowRow(
    BuildContext context,
    AppLocalizations l10n,
    TransactionsListState s,
  ) {
    if (s.searchingHistory) {
      return Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.transactionsSearchSearchingHistory,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }
    if (s.historyScanHitLimit && s.debouncedSearchQuery.isNotEmpty) {
      return Text(
        l10n.transactionsSearchHistoryLimitReached,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return null;
  }

  String _amount(
    BuildContext context,
    LedgerTransaction t, {
    required int minor,
    required String currency,
  }) {
    final loc = Localizations.localeOf(context).toLanguageTag();
    final sign = t.direction == MoneyDirection.in_ ? '+' : '−';
    return '$sign${formatMinorUnits(minor, currency, loc)}';
  }

  String? _secondaryAmount(
    BuildContext context,
    LedgerTransaction t,
    String mainCurrency,
  ) {
    if (t.currency == mainCurrency || t.amountMinorMain == null) {
      return null;
    }
    final loc = Localizations.localeOf(context).toLanguageTag();
    return formatMinorUnitsWithCode(t.amountMinor, t.currency, loc);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listState = ref.watch(transactionsListNotifierProvider);
    final notifier = ref.read(transactionsListNotifierProvider.notifier);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final mainCurrency =
        profileAsync.valueOrNull?.mainCurrency ??
        accountsAsync.valueOrNull?.firstOrNull?.currency ??
        'MXN';

    final filtered = notifier.filteredItems();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ShellDrawerController.open(context),
          tooltip: l10n.openShellMenu,
          icon: const Icon(Icons.settings_outlined),
        ),
        title: Text(l10n.transactionsTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FinkoSearchFilterBar(
              controller: _search,
              hintText: l10n.transactionsSearchHint,
              onChanged: (v) => ref
                  .read(transactionsListNotifierProvider.notifier)
                  .onSearchRawChanged(v),
              onFilterTap: _openFilterSheet,
              filterTooltip: _filterTooltip(l10n, listState),
              belowSearch: _historyBelowRow(context, l10n, listState),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: listState.loadingInitial && listState.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : listState.error != null && listState.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${listState.error}'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => notifier.refresh(),
                            child: Text(l10n.actionRetry),
                          ),
                        ],
                      ),
                    ),
                  )
                : FinkoPaperCard(
                    padding: EdgeInsets.zero,
                    child: RefreshIndicator(
                      onRefresh: () => notifier.refresh(),
                      child: Builder(
                        builder: (context) {
                          if (filtered.isEmpty) {
                            final emptyMessage =
                                listState.debouncedSearchQuery.isNotEmpty
                                ? l10n.transactionsSearchNoMatches
                                : l10n.emptyNoTransactions;
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _scroll,
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.35,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        emptyMessage,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return ListView.builder(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                filtered.length +
                                (listState.loadingMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i >= filtered.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final t = filtered[i];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (i > 0) const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: FinkoTransactionRowCompact(
                                      title: t.memo ?? t.type.wireName,
                                      subtitle: t.transactionDate,
                                      amountText: _amount(
                                        context,
                                        t,
                                        minor:
                                            t.amountMinorMain != null &&
                                                t.currency != mainCurrency
                                            ? t.amountMinorMain!
                                            : t.amountMinor,
                                        currency: mainCurrency,
                                      ),
                                      secondaryAmountText: _secondaryAmount(
                                        context,
                                        t,
                                        mainCurrency,
                                      ),
                                      onTap: () =>
                                          LedgerTransactionEditorSheet.show(
                                            context,
                                            transaction: t,
                                          ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
