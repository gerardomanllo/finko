import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/firebase_auth_providers.dart';
import '../firestore_paths.dart';
import '../models/models.dart';
import 'ledger_transaction_firestore_maps.dart';

/// Firestore reads for dashboard and lists — [`docs/data-contract.md`].
abstract class FirestoreDataRepository {
  Stream<UserProfile?> watchUserProfile(String uid);

  Stream<List<FinkoAccount>> watchAccounts(String uid);

  /// Emits `null` when the month doc is missing.
  Stream<MonthlyTotals?> watchMonthlyTotals(String uid, String yyyyMm);

  Stream<List<LedgerTransaction>> watchRecentTransactions(
    String uid, {
    int limit = 20,
  });

  /// Ledger rows with [transactionDate] **strictly after** [afterYyyyMmDd], ascending.
  ///
  /// Used for dashboard “próximos” alongside `upcomingTransactions` (user-entered
  /// future-dated ledger rows are not duplicated in that collection).
  Stream<List<LedgerTransaction>> watchLedgerTransactionsAfterDate(
    String uid,
    String afterYyyyMmDd, {
    int limit = 40,
  });

  /// Paged ledger read (newest first). Use [startAfter] from the previous page’s [TransactionsPageResult.lastDocument].
  Future<TransactionsPageResult> fetchTransactionsPage(
    String uid, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = 20,
  });

  /// Upcoming rows with [transactionDate] on or after [fromYyyyMmDd] (inclusive).
  Stream<List<UpcomingTransaction>> watchUpcomingFromDate(
    String uid,
    String fromYyyyMmDd, {
    int limit = 50,
  });

  Stream<List<FinkoCategory>> watchCategories(String uid);

  Stream<List<RecurringRule>> watchRecurringRules(String uid);

  /// Global `forexRates/{yyyy-mm-dd}` doc; `null` if missing.
  Stream<ForexRatesDoc?> watchForexRates(String yyyyMmDd);

  /// Creates a new `transactions/{id}` doc. Returns the new document id.
  /// Does not set server-owned aggregate audit fields — see [`docs/data-model.md`] §4.
  Future<String> createTransaction(String uid, LedgerTransaction data);

  /// Reads a single ledger row (e.g. the other leg of a transfer).
  Future<LedgerTransaction?> fetchTransaction(String uid, String transactionId);

  /// Atomically creates two linked `transferLeg` documents ([`docs/data-model.md`] §4).
  /// Out leg: [fromAccountId]; in leg: [toAccountId]. Both use [currency] and [amountMinor].
  Future<({String fromLegId, String toLegId})> createTransferLegPair(
    String uid, {
    required String transactionDate,
    required int amountMinor,
    required String fromAccountId,
    required String toAccountId,
    required String currency,
    String? memo,
  });

  /// Updates both legs of a transfer in one batch.
  Future<void> updateTransferLegPair(
    String uid,
    LedgerTransaction outLeg,
    LedgerTransaction inLeg,
  );

  /// Updates an existing transaction. [data.id] must match the document id.
  Future<void> updateTransaction(String uid, LedgerTransaction data);

  /// Hard-deletes a transaction ([`docs/data-model.md`] §4).
  Future<void> deleteTransaction(String uid, String transactionId);
}

class FirebaseFirestoreDataRepository implements FirestoreDataRepository {
  FirebaseFirestoreDataRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _db.doc(FirestorePaths.userDoc(uid)).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfile.fromFirestore(uid, snapshot.data()!);
    });
  }

  @override
  Stream<List<FinkoAccount>> watchAccounts(String uid) {
    return _db
        .collection(FirestorePaths.accountsCollection(uid))
        .snapshots()
        .map((snapshot) {
          final accounts = snapshot.docs
              .map((d) => FinkoAccount.fromFirestore(d.id, d.data()))
              .toList();
          accounts.sort((a, b) {
            final byOrder = a.sortOrder.compareTo(b.sortOrder);
            if (byOrder != 0) return byOrder;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          return accounts;
        });
  }

  @override
  Stream<MonthlyTotals?> watchMonthlyTotals(String uid, String yyyyMm) {
    return _db
        .doc(FirestorePaths.monthlyTotalsDoc(uid, yyyyMm))
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return MonthlyTotals.fromFirestore(snapshot.data()!);
        });
  }

  @override
  Stream<List<LedgerTransaction>> watchRecentTransactions(
    String uid, {
    int limit = 20,
  }) {
    return _db
        .collection(FirestorePaths.transactionsCollection(uid))
        .orderBy('transactionDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => LedgerTransaction.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Stream<List<LedgerTransaction>> watchLedgerTransactionsAfterDate(
    String uid,
    String afterYyyyMmDd, {
    int limit = 40,
  }) {
    return _db
        .collection(FirestorePaths.transactionsCollection(uid))
        .where('transactionDate', isGreaterThan: afterYyyyMmDd)
        .orderBy('transactionDate')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => LedgerTransaction.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<TransactionsPageResult> fetchTransactionsPage(
    String uid, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = 20,
  }) async {
    var query = _db
        .collection(FirestorePaths.transactionsCollection(uid))
        .orderBy('transactionDate', descending: true)
        .limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    final items = snapshot.docs
        .map((d) => LedgerTransaction.fromFirestore(d.id, d.data()))
        .toList();
    final hasMore = snapshot.docs.length == pageSize;
    final lastDocument = items.isEmpty ? null : snapshot.docs.last;
    return TransactionsPageResult(
      items: items,
      hasMore: hasMore,
      lastDocument: lastDocument,
    );
  }

  @override
  Stream<List<UpcomingTransaction>> watchUpcomingFromDate(
    String uid,
    String fromYyyyMmDd, {
    int limit = 50,
  }) {
    return _db
        .collection(FirestorePaths.upcomingTransactionsCollection(uid))
        .where('transactionDate', isGreaterThanOrEqualTo: fromYyyyMmDd)
        .orderBy('transactionDate')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => UpcomingTransaction.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Stream<List<FinkoCategory>> watchCategories(String uid) {
    return _db
        .collection(FirestorePaths.categoriesCollection(uid))
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((d) => FinkoCategory.fromFirestore(d.id, d.data()))
              .toList();
          list.sort((a, b) {
            final byOrder = a.sortOrder.compareTo(b.sortOrder);
            if (byOrder != 0) return byOrder;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          return list;
        });
  }

  @override
  Stream<List<RecurringRule>> watchRecurringRules(String uid) {
    return _db
        .collection(FirestorePaths.recurringCollection(uid))
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((d) => RecurringRule.fromFirestore(d.id, d.data()))
              .where((r) => r.active)
              .toList();
          list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return list;
        });
  }

  @override
  Stream<ForexRatesDoc?> watchForexRates(String yyyyMmDd) {
    return _db.doc(FirestorePaths.forexRatesDoc(yyyyMmDd)).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ForexRatesDoc.fromFirestore(yyyyMmDd, snapshot.data()!);
    });
  }

  @override
  Future<LedgerTransaction?> fetchTransaction(
    String uid,
    String transactionId,
  ) async {
    final snap = await _db
        .doc(FirestorePaths.transactionDoc(uid, transactionId))
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return LedgerTransaction.fromFirestore(snap.id, snap.data()!);
  }

  @override
  Future<({String fromLegId, String toLegId})> createTransferLegPair(
    String uid, {
    required String transactionDate,
    required int amountMinor,
    required String fromAccountId,
    required String toAccountId,
    required String currency,
    String? memo,
  }) async {
    final col = _db.collection(FirestorePaths.transactionsCollection(uid));
    final batch = _db.batch();
    final groupId = col.doc().id;
    final fromRef = col.doc();
    final toRef = col.doc();
    final fromId = fromRef.id;
    final toId = toRef.id;
    final ph = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final fromLeg = LedgerTransaction(
      id: fromId,
      transactionDate: transactionDate,
      loadedAt: ph,
      amountMinor: amountMinor,
      direction: MoneyDirection.out_,
      currency: currency,
      accountId: fromAccountId,
      categoryId: null,
      type: LedgerTransactionKind.transferLeg,
      memo: memo,
      transferGroupId: groupId,
      linkedTransactionId: toId,
      sourceUpcomingId: null,
      amountMinorMain: null,
      fxRateDateUsed: null,
      createdAt: ph,
      updatedAt: ph,
    );
    final toLeg = LedgerTransaction(
      id: toId,
      transactionDate: transactionDate,
      loadedAt: ph,
      amountMinor: amountMinor,
      direction: MoneyDirection.in_,
      currency: currency,
      accountId: toAccountId,
      categoryId: null,
      type: LedgerTransactionKind.transferLeg,
      memo: memo,
      transferGroupId: groupId,
      linkedTransactionId: fromId,
      sourceUpcomingId: null,
      amountMinorMain: null,
      fxRateDateUsed: null,
      createdAt: ph,
      updatedAt: ph,
    );

    batch.set(fromRef, ledgerTransactionCreateMap(fromLeg));
    batch.set(toRef, ledgerTransactionCreateMap(toLeg));
    await batch.commit();
    return (fromLegId: fromId, toLegId: toId);
  }

  @override
  Future<void> updateTransferLegPair(
    String uid,
    LedgerTransaction outLeg,
    LedgerTransaction inLeg,
  ) async {
    final batch = _db.batch();
    batch.update(
      _db.doc(FirestorePaths.transactionDoc(uid, outLeg.id)),
      ledgerTransactionUpdateMap(outLeg),
    );
    batch.update(
      _db.doc(FirestorePaths.transactionDoc(uid, inLeg.id)),
      ledgerTransactionUpdateMap(inLeg),
    );
    await batch.commit();
  }

  @override
  Future<String> createTransaction(String uid, LedgerTransaction data) async {
    final col = _db.collection(FirestorePaths.transactionsCollection(uid));
    final doc = col.doc();
    await doc.set(ledgerTransactionCreateMap(data));
    return doc.id;
  }

  @override
  Future<void> updateTransaction(String uid, LedgerTransaction data) async {
    await _db
        .doc(FirestorePaths.transactionDoc(uid, data.id))
        .update(ledgerTransactionUpdateMap(data));
  }

  @override
  Future<void> deleteTransaction(String uid, String transactionId) async {
    await _db.doc(FirestorePaths.transactionDoc(uid, transactionId)).delete();
  }
}

final firestoreDataRepositoryProvider = Provider<FirestoreDataRepository>(
  (ref) => FirebaseFirestoreDataRepository(ref.watch(firestoreProvider)),
);
