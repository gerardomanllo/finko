import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:finko/core/data/models/models.dart';
import 'package:finko/core/data/repositories/firestore_data_repository.dart';

/// Test double with static controllable streams.
class FakeFirestoreDataRepository implements FirestoreDataRepository {
  FakeFirestoreDataRepository({
    Stream<UserProfile?>? profile,
    Stream<List<FinkoAccount>>? accounts,
    Stream<MonthlyTotals?>? monthly,
    Stream<List<LedgerTransaction>>? recent,
    Stream<List<LedgerTransaction>>? ledgerAfterDate,
    Stream<List<UpcomingTransaction>>? upcoming,
    Stream<List<FinkoCategory>>? categories,
    Stream<List<RecurringRule>>? recurringRules,
    Stream<ForexRatesDoc?>? forex,
  }) : _profile = profile ?? Stream<UserProfile?>.value(null),
       _accounts = accounts ?? Stream<List<FinkoAccount>>.value(const []),
       _monthly = monthly ?? Stream<MonthlyTotals?>.value(null),
       _recent = recent ?? Stream<List<LedgerTransaction>>.value(const []),
       _ledgerAfterDate =
           ledgerAfterDate ?? Stream<List<LedgerTransaction>>.value(const []),
       _upcoming =
           upcoming ?? Stream<List<UpcomingTransaction>>.value(const []),
       _categories = categories ?? Stream<List<FinkoCategory>>.value(const []),
       _recurringRules =
           recurringRules ?? Stream<List<RecurringRule>>.value(const []),
       _forex = forex ?? Stream<ForexRatesDoc?>.value(null);

  final Stream<UserProfile?> _profile;
  final Stream<List<FinkoAccount>> _accounts;
  final Stream<MonthlyTotals?> _monthly;
  final Stream<List<LedgerTransaction>> _recent;
  final Stream<List<LedgerTransaction>> _ledgerAfterDate;
  final Stream<List<UpcomingTransaction>> _upcoming;
  final Stream<List<FinkoCategory>> _categories;
  final Stream<List<RecurringRule>> _recurringRules;
  final Stream<ForexRatesDoc?> _forex;

  @override
  Stream<UserProfile?> watchUserProfile(String uid) => _profile;

  @override
  Stream<List<FinkoAccount>> watchAccounts(String uid) => _accounts;

  @override
  Stream<MonthlyTotals?> watchMonthlyTotals(String uid, String yyyyMm) =>
      _monthly;

  @override
  Stream<List<LedgerTransaction>> watchRecentTransactions(
    String uid, {
    int limit = 20,
  }) => _recent;

  @override
  Stream<List<LedgerTransaction>> watchTransactionsForDateRange(
    String uid, {
    required String startYyyyMmDd,
    required String endYyyyMmDd,
  }) => _recent;

  @override
  Stream<List<LedgerTransaction>> watchLedgerTransactionsAfterDate(
    String uid,
    String afterYyyyMmDd, {
    int limit = 40,
  }) => _ledgerAfterDate;

  @override
  Future<TransactionsPageResult> fetchTransactionsPage(
    String uid, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = 20,
  }) async {
    return const TransactionsPageResult(
      items: [],
      hasMore: false,
      lastDocument: null,
    );
  }

  @override
  Future<LedgerTransaction?> fetchTransaction(
    String uid,
    String transactionId,
  ) async => null;

  @override
  Future<({String fromLegId, String toLegId})> createTransferLegPair(
    String uid, {
    required String transactionDate,
    required int amountMinor,
    required String fromAccountId,
    required String toAccountId,
    required String currency,
    String? memo,
  }) async => (fromLegId: 'fake_from', toLegId: 'fake_to');

  @override
  Future<void> updateTransferLegPair(
    String uid,
    LedgerTransaction outLeg,
    LedgerTransaction inLeg,
  ) async {}

  @override
  Future<String> createTransaction(String uid, LedgerTransaction data) async =>
      'fake_tx';

  @override
  Future<void> updateTransaction(String uid, LedgerTransaction data) async {}

  @override
  Future<void> deleteTransaction(String uid, String transactionId) async {}

  @override
  Future<void> updateCategory(String uid, FinkoCategory category) async {}

  @override
  Future<void> updateAccountMetadata(String uid, FinkoAccount account) async {}

  @override
  Stream<List<UpcomingTransaction>> watchUpcomingFromDate(
    String uid,
    String fromYyyyMmDd, {
    int limit = 50,
  }) => _upcoming;

  @override
  Stream<ForexRatesDoc?> watchForexRates(String yyyyMmDd) => _forex;

  @override
  Stream<List<FinkoCategory>> watchCategories(String uid) => _categories;

  @override
  Stream<List<RecurringRule>> watchRecurringRules(String uid) =>
      _recurringRules;
}
