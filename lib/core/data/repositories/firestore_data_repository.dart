import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/firebase_auth_providers.dart';
import '../firestore_paths.dart';
import '../models/models.dart';

/// Firestore reads for dashboard and lists — [`docs/data-contract.md`].
abstract class FirestoreDataRepository {
  Stream<List<FinkoAccount>> watchAccounts(String uid);

  /// Emits `null` when the month doc is missing.
  Stream<MonthlyTotals?> watchMonthlyTotals(String uid, String yyyyMm);

  Stream<List<LedgerTransaction>> watchRecentTransactions(
    String uid, {
    int limit = 20,
  });

  /// Upcoming rows with [transactionDate] on or after [fromYyyyMmDd] (inclusive).
  Stream<List<UpcomingTransaction>> watchUpcomingFromDate(
    String uid,
    String fromYyyyMmDd, {
    int limit = 50,
  });

  /// Global `forexRates/{yyyy-mm-dd}` doc; `null` if missing.
  Stream<ForexRatesDoc?> watchForexRates(String yyyyMmDd);
}

class FirebaseFirestoreDataRepository implements FirestoreDataRepository {
  FirebaseFirestoreDataRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<FinkoAccount>> watchAccounts(String uid) {
    return _db
        .collection(FirestorePaths.accountsCollection(uid))
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => FinkoAccount.fromFirestore(d.id, d.data()))
              .toList(),
        );
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
  Stream<ForexRatesDoc?> watchForexRates(String yyyyMmDd) {
    return _db.doc(FirestorePaths.forexRatesDoc(yyyyMmDd)).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ForexRatesDoc.fromFirestore(yyyyMmDd, snapshot.data()!);
    });
  }
}

final firestoreDataRepositoryProvider = Provider<FirestoreDataRepository>(
  (ref) => FirebaseFirestoreDataRepository(ref.watch(firestoreProvider)),
);
