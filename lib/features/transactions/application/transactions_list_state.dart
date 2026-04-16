import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/ledger_transaction.dart';

/// Filter ring: All → standard → transferLeg → adjustment → All ([`LedgerTransactionKind`]).
class TransactionsListState {
  const TransactionsListState({
    required this.items,
    required this.loadingInitial,
    required this.loadingMore,
    required this.hasMoreFromServer,
    required this.lastDocument,
    required this.rawSearchQuery,
    required this.debouncedSearchQuery,
    required this.filterIndex,
    required this.searchingHistory,
    required this.historyScanHitLimit,
    this.error,
  });

  factory TransactionsListState.empty() => const TransactionsListState(
    items: [],
    loadingInitial: false,
    loadingMore: false,
    hasMoreFromServer: false,
    lastDocument: null,
    rawSearchQuery: '',
    debouncedSearchQuery: '',
    filterIndex: 0,
    searchingHistory: false,
    historyScanHitLimit: false,
  );

  factory TransactionsListState.initialLoading() => const TransactionsListState(
    items: [],
    loadingInitial: true,
    loadingMore: false,
    hasMoreFromServer: true,
    lastDocument: null,
    rawSearchQuery: '',
    debouncedSearchQuery: '',
    filterIndex: 0,
    searchingHistory: false,
    historyScanHitLimit: false,
  );

  final List<LedgerTransaction> items;
  final bool loadingInitial;
  final bool loadingMore;

  /// False when the last fetch returned fewer than a full page.
  final bool hasMoreFromServer;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  final String rawSearchQuery;
  final String debouncedSearchQuery;

  /// 0 = all kinds; 1–3 map to [LedgerTransactionKind] in order.
  final int filterIndex;

  final bool searchingHistory;

  /// True when background scan stopped due to [kMaxHistoryScanPages].
  final bool historyScanHitLimit;

  final Object? error;

  LedgerTransactionKind? get activeKindFilter {
    switch (filterIndex % 4) {
      case 0:
        return null;
      case 1:
        return LedgerTransactionKind.standard;
      case 2:
        return LedgerTransactionKind.transferLeg;
      case 3:
        return LedgerTransactionKind.adjustment;
      default:
        return null;
    }
  }

  TransactionsListState copyWith({
    List<LedgerTransaction>? items,
    bool? loadingInitial,
    bool? loadingMore,
    bool? hasMoreFromServer,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool clearLastDocument = false,
    String? rawSearchQuery,
    String? debouncedSearchQuery,
    int? filterIndex,
    bool? searchingHistory,
    bool? historyScanHitLimit,
    Object? error,
    bool clearError = false,
  }) {
    return TransactionsListState(
      items: items ?? this.items,
      loadingInitial: loadingInitial ?? this.loadingInitial,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMoreFromServer: hasMoreFromServer ?? this.hasMoreFromServer,
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      rawSearchQuery: rawSearchQuery ?? this.rawSearchQuery,
      debouncedSearchQuery: debouncedSearchQuery ?? this.debouncedSearchQuery,
      filterIndex: filterIndex ?? this.filterIndex,
      searchingHistory: searchingHistory ?? this.searchingHistory,
      historyScanHitLimit: historyScanHitLimit ?? this.historyScanHitLimit,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
