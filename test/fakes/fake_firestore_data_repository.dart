import 'package:finko/core/data/models/models.dart';
import 'package:finko/core/data/repositories/firestore_data_repository.dart';

/// Test double with static controllable streams.
class FakeFirestoreDataRepository implements FirestoreDataRepository {
  FakeFirestoreDataRepository({
    Stream<UserProfile?>? profile,
    Stream<List<FinkoAccount>>? accounts,
    Stream<MonthlyTotals?>? monthly,
    Stream<List<LedgerTransaction>>? recent,
    Stream<List<UpcomingTransaction>>? upcoming,
    Stream<List<FinkoCategory>>? categories,
    Stream<List<RecurringRule>>? recurringRules,
    Stream<ForexRatesDoc?>? forex,
  }) : _profile = profile ?? Stream<UserProfile?>.value(null),
       _accounts = accounts ?? Stream<List<FinkoAccount>>.value(const []),
       _monthly = monthly ?? Stream<MonthlyTotals?>.value(null),
       _recent = recent ?? Stream<List<LedgerTransaction>>.value(const []),
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
