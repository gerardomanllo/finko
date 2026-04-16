import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/repositories/firestore_data_repository.dart';
import 'transactions_list_state.dart';

final transactionsListNotifierProvider =
    NotifierProvider<TransactionsListNotifier, TransactionsListState>(
      TransactionsListNotifier.new,
    );

class TransactionsListNotifier extends Notifier<TransactionsListState> {
  static const int _debounceMs = 350;
  static const int _pageSize = 20;
  static const int _maxHistoryScanPages = 100;
  static const double _scrollLoadThresholdPx = 200;

  Timer? _debounce;
  int _searchGen = 0;
  int _historyGen = 0;

  FirestoreDataRepository get _repo =>
      ref.read(firestoreDataRepositoryProvider);

  @override
  TransactionsListState build() {
    ref.onDispose(() => _debounce?.cancel());
    final uid = ref.watch(authUidProvider);
    if (uid == null) {
      _debounce?.cancel();
      return TransactionsListState.empty();
    }
    Future.microtask(() => _loadInitial(uid));
    return TransactionsListState.initialLoading();
  }

  void onSearchRawChanged(String value) {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    state = state.copyWith(rawSearchQuery: value);
    _debounce?.cancel();
    _searchGen++;
    final gen = _searchGen;
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (gen != _searchGen) return;
      final q = value.trim().toLowerCase();
      state = state.copyWith(debouncedSearchQuery: q);
      _maybeStartHistoryScan(uid);
    });
  }

  /// [index] 0 = all kinds, 1–3 = [LedgerTransactionKind] in enum order.
  void setFilterIndex(int index) {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    final next = index % 4;
    if (next == state.filterIndex % 4) return;
    _historyGen++;
    state = state.copyWith(filterIndex: next);
    _maybeStartHistoryScan(uid);
  }

  /// Call from a scroll view when near the bottom.
  void onScroll(ScrollMetrics metrics) {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    if (state.loadingMore || state.loadingInitial || state.searchingHistory) {
      return;
    }
    if (!state.hasMoreFromServer) return;
    if (metrics.maxScrollExtent <= 0) return;
    if (metrics.pixels < metrics.maxScrollExtent - _scrollLoadThresholdPx) {
      return;
    }
    unawaited(_loadMore(uid));
  }

  Future<void> refresh() async {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    _historyGen++;
    await _loadInitial(uid, force: true);
  }

  Future<void> _loadInitial(String uid, {bool force = false}) async {
    if (!force && !state.loadingInitial && state.items.isNotEmpty) return;
    state = state.copyWith(
      loadingInitial: true,
      clearError: true,
      items: force ? [] : state.items,
      hasMoreFromServer: true,
      clearLastDocument: force,
      searchingHistory: false,
      historyScanHitLimit: false,
    );
    try {
      final page = await _repo.fetchTransactionsPage(uid, pageSize: _pageSize);
      state = state.copyWith(
        items: page.items,
        loadingInitial: false,
        hasMoreFromServer: page.hasMore,
        lastDocument: page.lastDocument,
        loadingMore: false,
      );
      _maybeStartHistoryScan(uid);
    } catch (e) {
      state = state.copyWith(loadingInitial: false, error: e);
    }
  }

  Future<void> _loadMore(String uid) async {
    if (!state.hasMoreFromServer || state.lastDocument == null) return;
    if (state.loadingMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.fetchTransactionsPage(
        uid,
        startAfter: state.lastDocument,
        pageSize: _pageSize,
      );
      final merged = _mergeById(state.items, page.items);
      state = state.copyWith(
        items: merged,
        loadingMore: false,
        hasMoreFromServer: page.hasMore,
        lastDocument: page.lastDocument ?? state.lastDocument,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e);
    }
  }

  void _maybeStartHistoryScan(String uid) {
    final q = state.debouncedSearchQuery;
    if (q.isEmpty) {
      _historyGen++;
      state = state.copyWith(
        searchingHistory: false,
        historyScanHitLimit: false,
      );
      return;
    }
    final filtered = _filteredItems();
    if (filtered.isNotEmpty) {
      _historyGen++;
      state = state.copyWith(
        searchingHistory: false,
        historyScanHitLimit: false,
      );
      return;
    }
    if (!state.hasMoreFromServer || state.lastDocument == null) {
      _historyGen++;
      state = state.copyWith(
        searchingHistory: false,
        historyScanHitLimit: false,
      );
      return;
    }
    _historyGen++;
    final gen = _historyGen;
    unawaited(_runHistoryScan(uid, gen));
  }

  Future<void> _runHistoryScan(String uid, int gen) async {
    state = state.copyWith(searchingHistory: true, historyScanHitLimit: false);
    var pages = 0;
    var lastDoc = state.lastDocument;
    var hasMore = state.hasMoreFromServer;

    while (gen == _historyGen &&
        ref.read(authUidProvider) == uid &&
        hasMore &&
        lastDoc != null) {
      if (pages >= _maxHistoryScanPages) {
        state = state.copyWith(
          searchingHistory: false,
          historyScanHitLimit: true,
        );
        return;
      }
      pages++;
      try {
        final page = await _repo.fetchTransactionsPage(
          uid,
          startAfter: lastDoc,
          pageSize: _pageSize,
        );
        if (gen != _historyGen) return;
        final merged = _mergeById(state.items, page.items);
        hasMore = page.hasMore;
        lastDoc = page.lastDocument;
        state = state.copyWith(
          items: merged,
          hasMoreFromServer: hasMore,
          lastDocument: lastDoc,
          loadingMore: false,
        );
        if (_filteredItems().isNotEmpty) {
          state = state.copyWith(
            searchingHistory: false,
            historyScanHitLimit: false,
          );
          return;
        }
        if (!hasMore || lastDoc == null) {
          state = state.copyWith(
            searchingHistory: false,
            historyScanHitLimit: false,
          );
          return;
        }
      } catch (e) {
        state = state.copyWith(searchingHistory: false, error: e);
        return;
      }
    }
    if (gen == _historyGen) {
      state = state.copyWith(searchingHistory: false);
    }
  }

  List<LedgerTransaction> _filteredItems() {
    final q = state.debouncedSearchQuery;
    final kind = state.activeKindFilter;
    return state.items.where((t) => _matches(t, q, kind)).toList();
  }

  List<LedgerTransaction> filteredItems() {
    final q = state.debouncedSearchQuery;
    final kind = state.activeKindFilter;
    return state.items.where((t) => _matches(t, q, kind)).toList();
  }

  static bool _matches(
    LedgerTransaction t,
    String q,
    LedgerTransactionKind? kind,
  ) {
    if (kind != null && t.type != kind) return false;
    if (q.isEmpty) return true;
    final memo = (t.memo ?? '').toLowerCase();
    final id = t.id.toLowerCase();
    return memo.contains(q) || id.contains(q);
  }

  static List<LedgerTransaction> _mergeById(
    List<LedgerTransaction> a,
    List<LedgerTransaction> b,
  ) {
    final seen = <String>{...a.map((e) => e.id)};
    final out = [...a];
    for (final t in b) {
      if (seen.add(t.id)) out.add(t);
    }
    return out;
  }
}
