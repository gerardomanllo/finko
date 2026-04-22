/// Firestore paths from [docs/data-model.md].
abstract final class FirestorePaths {
  static const users = 'users';

  static String userDoc(String uid) => '$users/$uid';

  /// Server-written Telegram bot link state (`chatId`, `username`, …) — client may **read** only.
  static String telegramLinkStateDoc(String uid) =>
      '$users/$uid/_telegramLink/state';

  static String transactionsCollection(String uid) =>
      '$users/$uid/transactions';

  static String transactionDoc(String uid, String txId) =>
      '${transactionsCollection(uid)}/$txId';

  static String accountsCollection(String uid) => '$users/$uid/accounts';

  static String accountDoc(String uid, String accountId) =>
      '${accountsCollection(uid)}/$accountId';

  static String categoriesCollection(String uid) => '$users/$uid/categories';

  static String categoryDoc(String uid, String categoryId) =>
      '${categoriesCollection(uid)}/$categoryId';

  static String monthlyTotalsCollection(String uid) =>
      '$users/$uid/monthlyTotals';

  static String monthlyTotalsDoc(String uid, String yyyyMm) =>
      '${monthlyTotalsCollection(uid)}/$yyyyMm';

  static String upcomingTransactionsCollection(String uid) =>
      '$users/$uid/upcomingTransactions';

  static String upcomingTransactionDoc(String uid, String id) =>
      '${upcomingTransactionsCollection(uid)}/$id';

  static String recurringCollection(String uid) => '$users/$uid/recurring';

  static String recurringDoc(String uid, String ruleId) =>
      '${recurringCollection(uid)}/$ruleId';

  static String processedAggregateEventsCollection(String uid) =>
      '$users/$uid/_processedAggregateEvents';

  static String processedAggregateEventDoc(String uid, String eventId) =>
      '${processedAggregateEventsCollection(uid)}/$eventId';

  /// Global daily FX cache (not user-scoped).
  static const forexRates = 'forexRates';

  static String forexRatesDoc(String yyyyMmDd) => '$forexRates/$yyyyMmDd';
}
