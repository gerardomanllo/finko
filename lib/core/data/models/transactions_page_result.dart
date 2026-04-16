import 'package:cloud_firestore/cloud_firestore.dart';

import 'ledger_transaction.dart';

/// One page from `users/{uid}/transactions` ordered by [LedgerTransaction.transactionDate] desc.
class TransactionsPageResult {
  const TransactionsPageResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });

  final List<LedgerTransaction> items;

  /// Whether another page might exist (this page was full).
  final bool hasMore;

  /// Last Firestore doc in [items]; pass to the next [FirestoreDataRepository.fetchTransactionsPage] as [startAfter].
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}
