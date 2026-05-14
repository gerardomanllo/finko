import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/firebase_auth_providers.dart';
import '../firestore_paths.dart';
import '../../spending/fixed_variable_expense.dart'
    show kFixedExpensesCategoryId;
import '../ledger_category_ids.dart';
import '../models/models.dart';
import 'ledger_transaction_firestore_maps.dart';

Future<Set<String>> _collectTransactionIdsForAccountDelete(
  FirebaseFirestore db,
  String uid,
  String accountId,
) async {
  final txCol = db.collection(FirestorePaths.transactionsCollection(uid));
  final snap = await txCol.where('accountId', isEqualTo: accountId).get();
  final ids = <String>{};
  final groupIds = <String>{};
  for (final d in snap.docs) {
    ids.add(d.id);
    final data = d.data();
    if (data['type'] == 'transferLeg') {
      final g = data['transferGroupId'] as String?;
      if (g != null && g.isNotEmpty) groupIds.add(g);
    }
  }
  for (final g in groupIds) {
    final pair = await txCol.where('transferGroupId', isEqualTo: g).get();
    for (final d in pair.docs) {
      ids.add(d.id);
    }
  }
  return ids;
}

List<List<T>> _chunkList<T>(List<T> list, int size) {
  final out = <List<T>>[];
  for (var i = 0; i < list.length; i += size) {
    final end = i + size > list.length ? list.length : i + size;
    out.add(list.sublist(i, end));
  }
  return out;
}

/// Firestore reads for dashboard and lists — [`docs/data-contract.md`].
abstract class FirestoreDataRepository {
  Stream<UserProfile?> watchUserProfile(String uid);

  /// Fresh read for ledger refresh gate ([`Source.server`]).
  Future<UserProfile?> fetchUserProfileSync(String uid);

  Stream<List<FinkoAccount>> watchAccounts(String uid);

  /// Emits `null` when the month doc is missing.
  Stream<MonthlyTotals?> watchMonthlyTotals(String uid, String yyyyMm);

  Stream<List<LedgerTransaction>> watchRecentTransactions(
    String uid, {
    int limit = 20,
  });

  /// Inclusive [`transactionDate`] range, ordered ascending by date ([`docs/data-contract.md`] Spending).
  Stream<List<LedgerTransaction>> watchTransactionsForDateRange(
    String uid, {
    required String startYyyyMmDd,
    required String endYyyyMmDd,
  });

  /// Ledger rows with [transactionDate] ordered ascending, limited by [limit].
  ///
  /// When [inclusiveFrom] is **false** (default), dates are **strictly after**
  /// [afterYyyyMmDd] — dashboard próximos strip (no “today” ledger previews).
  ///
  /// When **true**, dates are **on or after** [afterYyyyMmDd] — Recurring tab merge
  /// with [includeDueToday] (today’s future-dated ledger rows).
  ///
  /// Used alongside `upcomingTransactions` (user-entered future-dated ledger rows
  /// are not duplicated in that collection).
  Stream<List<LedgerTransaction>> watchLedgerTransactionsAfterDate(
    String uid,
    String afterYyyyMmDd, {
    int limit = 40,
    bool inclusiveFrom = false,
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
  /// Out leg uses [fromAmountMinor] / [fromCurrency]; in leg uses [toAmountMinor] / [toCurrency].
  Future<({String fromLegId, String toLegId})> createTransferLegPair(
    String uid, {
    required String transactionDate,
    required int fromAmountMinor,
    required String fromAccountId,
    required String fromCurrency,
    required int toAmountMinor,
    required String toAccountId,
    required String toCurrency,
    String? memo,
  });

  /// Ensures reserved transfer category exists (older accounts pre-onboarding update).
  Future<void> ensureLedgerTransferCategory(String uid);

  /// Creates `categories/{id}`; returns new id.
  Future<String> createCategory(
    String uid, {
    required String name,
    required CategoryKind kind,
    required String iconKey,
    int? colorArgb,
  });

  /// Creates `accounts/{id}` and optionally an opening-balance adjustment in one batch.
  ///
  /// When [startingBalanceMinor] is non-zero, [openingBalanceTransactionDateYyyyMmDd]
  /// must be the user's business calendar date (`yyyy-MM-dd`), typically
  /// `ref.read(todayYyyyMmDdProvider)` from `finko_stream_providers.dart` — not UTC midnight.
  Future<String> createAccount(
    String uid, {
    required String name,
    required FinkoAccountType type,
    required String currency,
    required int colorArgb,
    required String iconKey,
    int startingBalanceMinor = 0,
    String? openingBalanceTransactionDateYyyyMmDd,
  });

  /// Hard-deletes all transactions with this category, related rules/upcoming rows,
  /// budget entry, then the category doc.
  Future<void> deleteCategoryCascade(String uid, String categoryId);

  /// Hard-deletes transactions (including paired transfer legs), related rules/upcoming,
  /// then the account doc.
  Future<void> deleteAccountCascade(String uid, String accountId);

  Future<({int transactions, int recurring, int upcoming})>
  previewCategoryDelete(String uid, String categoryId);

  Future<({int transactions, int recurring, int upcoming})>
  previewAccountDelete(String uid, String accountId);

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

  /// Merges fields into `upcomingTransactions/{data.id}` ([`docs/data-model.md`] §8).
  Future<void> updateUpcomingTransaction(String uid, UpcomingTransaction data);

  /// Hard-deletes `upcomingTransactions/{upcomingId}`.
  Future<void> deleteUpcomingTransaction(String uid, String upcomingId);

  /// Merges fields into `recurring/{data.id}` ([`docs/data-model.md`] §9).
  Future<void> updateRecurringRule(String uid, RecurringRule data);

  /// User metadata on `categories/{id}` — does not touch aggregates.
  Future<void> updateCategory(String uid, FinkoCategory category);

  /// User metadata on `accounts/{id}` — does not change balances.
  Future<void> updateAccountMetadata(String uid, FinkoAccount account);
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
  Future<UserProfile?> fetchUserProfileSync(String uid) async {
    final snap = await _db
        .doc(FirestorePaths.userDoc(uid))
        .get(const GetOptions(source: Source.server));
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromFirestore(uid, snap.data()!);
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
  Stream<List<LedgerTransaction>> watchTransactionsForDateRange(
    String uid, {
    required String startYyyyMmDd,
    required String endYyyyMmDd,
  }) {
    return _db
        .collection(FirestorePaths.transactionsCollection(uid))
        .where('transactionDate', isGreaterThanOrEqualTo: startYyyyMmDd)
        .where('transactionDate', isLessThanOrEqualTo: endYyyyMmDd)
        .orderBy('transactionDate')
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
    bool inclusiveFrom = false,
  }) {
    final col = _db.collection(FirestorePaths.transactionsCollection(uid));
    final query = inclusiveFrom
        ? col
              .where('transactionDate', isGreaterThanOrEqualTo: afterYyyyMmDd)
              .orderBy('transactionDate')
              .limit(limit)
        : col
              .where('transactionDate', isGreaterThan: afterYyyyMmDd)
              .orderBy('transactionDate')
              .limit(limit);
    return query.snapshots().map(
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
              .where((c) => c.id != kLedgerTransferCategoryId)
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
  Future<void> ensureLedgerTransferCategory(String uid) async {
    await _db
        .doc(FirestorePaths.categoryDoc(uid, kLedgerTransferCategoryId))
        .set({
          'name': 'Transfers',
          'kind': CategoryKind.expense.wireName,
          'iconKey': 'swap_horiz',
          'sortOrder': -1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<({String fromLegId, String toLegId})> createTransferLegPair(
    String uid, {
    required String transactionDate,
    required int fromAmountMinor,
    required String fromAccountId,
    required String fromCurrency,
    required int toAmountMinor,
    required String toAccountId,
    required String toCurrency,
    String? memo,
  }) async {
    await ensureLedgerTransferCategory(uid);
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
      amountMinor: fromAmountMinor,
      direction: MoneyDirection.out_,
      currency: fromCurrency,
      accountId: fromAccountId,
      categoryId: kLedgerTransferCategoryId,
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
      amountMinor: toAmountMinor,
      direction: MoneyDirection.in_,
      currency: toCurrency,
      accountId: toAccountId,
      categoryId: kLedgerTransferCategoryId,
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

  @override
  Future<void> updateUpcomingTransaction(
    String uid,
    UpcomingTransaction data,
  ) async {
    final map = Map<String, dynamic>.from(data.toJson());
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .doc(FirestorePaths.upcomingTransactionDoc(uid, data.id))
        .set(map, SetOptions(merge: true));
  }

  @override
  Future<void> deleteUpcomingTransaction(String uid, String upcomingId) async {
    await _db
        .doc(FirestorePaths.upcomingTransactionDoc(uid, upcomingId))
        .delete();
  }

  @override
  Future<void> updateRecurringRule(String uid, RecurringRule data) async {
    final map = Map<String, dynamic>.from(data.toJson());
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .doc(FirestorePaths.recurringDoc(uid, data.id))
        .set(map, SetOptions(merge: true));
  }

  @override
  Future<void> updateCategory(String uid, FinkoCategory category) async {
    final payload = <String, dynamic>{
      'name': category.name,
      'kind': category.kind.wireName,
      'iconKey': category.iconKey,
      'sortOrder': category.sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final cur = category.currency?.trim();
    if (cur != null && cur.isNotEmpty) {
      payload['currency'] = cur;
    }
    if (category.colorArgb != null) {
      payload['colorArgb'] = category.colorArgb;
    }
    await _db.doc(FirestorePaths.categoryDoc(uid, category.id)).update(payload);
  }

  @override
  Future<void> updateAccountMetadata(String uid, FinkoAccount account) async {
    final payload = <String, dynamic>{
      'name': account.name,
      'type': account.type.wireName,
      'currency': account.currency,
      'includeInNetCash': account.includeInNetCash,
      'iconKey': account.iconKey,
      'colorArgb': account.colorArgb ?? 0xFF607D8B,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (account.creditLimitMinor != null) {
      payload['creditLimitMinor'] = account.creditLimitMinor;
    }
    if (account.isSystem) {
      payload['isSystem'] = true;
    }
    await _db.doc(FirestorePaths.accountDoc(uid, account.id)).update(payload);
  }

  @override
  Future<String> createCategory(
    String uid, {
    required String name,
    required CategoryKind kind,
    required String iconKey,
    int? colorArgb,
  }) async {
    final ref = _db.collection(FirestorePaths.categoriesCollection(uid)).doc();
    final payload = <String, dynamic>{
      'name': name.trim(),
      'kind': kind.wireName,
      'iconKey': iconKey.trim().isEmpty ? 'category' : iconKey.trim(),
      'sortOrder': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (colorArgb != null) payload['colorArgb'] = colorArgb;
    await ref.set(payload);
    return ref.id;
  }

  @override
  Future<String> createAccount(
    String uid, {
    required String name,
    required FinkoAccountType type,
    required String currency,
    required int colorArgb,
    required String iconKey,
    int startingBalanceMinor = 0,
    String? openingBalanceTransactionDateYyyyMmDd,
  }) async {
    final accountsCol = _db.collection(FirestorePaths.accountsCollection(uid));
    final ref = accountsCol.doc();
    final batch = _db.batch();
    final includeInNetCash =
        type == FinkoAccountType.cash ||
        type == FinkoAccountType.checking ||
        type == FinkoAccountType.creditCard;
    batch.set(ref, {
      'name': name.trim(),
      'type': type.wireName,
      'currency': currency.trim().toUpperCase(),
      'includeInNetCash': includeInNetCash,
      'colorArgb': colorArgb,
      'iconKey': iconKey.trim().isEmpty ? 'account_balance' : iconKey.trim(),
      'balanceMinor': 0,
      'sortOrder': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final start = startingBalanceMinor;
    if (start != 0) {
      final ymd = openingBalanceTransactionDateYyyyMmDd?.trim();
      if (ymd == null || ymd.isEmpty) {
        throw ArgumentError.value(
          openingBalanceTransactionDateYyyyMmDd,
          'openingBalanceTransactionDateYyyyMmDd',
          'required when startingBalanceMinor is non-zero (use profile calendar today, e.g. todayYyyyMmDdProvider)',
        );
      }
      final txRef = _db
          .collection(FirestorePaths.transactionsCollection(uid))
          .doc();
      final ph = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final adj = LedgerTransaction(
        id: txRef.id,
        transactionDate: ymd,
        loadedAt: ph,
        amountMinor: start.abs(),
        direction: openingBalanceDirectionForAccount(type, start),
        currency: currency.trim().toUpperCase(),
        accountId: ref.id,
        categoryId: kFixedExpensesCategoryId,
        type: LedgerTransactionKind.adjustment,
        memo: 'Opening balance',
        transferGroupId: null,
        linkedTransactionId: null,
        sourceUpcomingId: null,
        amountMinorMain: null,
        fxRateDateUsed: null,
        createdAt: ph,
        updatedAt: ph,
      );
      batch.set(txRef, ledgerTransactionCreateMap(adj));
    }
    await batch.commit();
    return ref.id;
  }

  @override
  Future<void> deleteCategoryCascade(String uid, String categoryId) async {
    if (categoryId == kFixedExpensesCategoryId ||
        categoryId == kLedgerTransferCategoryId) {
      throw ArgumentError.value(categoryId, 'categoryId', 'reserved category');
    }
    final txCol = _db.collection(FirestorePaths.transactionsCollection(uid));
    final snap = await txCol.where('categoryId', isEqualTo: categoryId).get();
    for (final part in _chunkList(snap.docs, 450)) {
      final b = _db.batch();
      for (final d in part) {
        b.delete(d.reference);
      }
      await b.commit();
    }

    Future<void> delByField(String field) async {
      final q = await _db
          .collection(FirestorePaths.recurringCollection(uid))
          .where(field, isEqualTo: categoryId)
          .get();
      for (final part in _chunkList(q.docs, 450)) {
        final b = _db.batch();
        for (final d in part) {
          b.delete(d.reference);
        }
        await b.commit();
      }
    }

    await delByField('categoryId');
    final upSnap = await _db
        .collection(FirestorePaths.upcomingTransactionsCollection(uid))
        .where('categoryId', isEqualTo: categoryId)
        .get();
    for (final part in _chunkList(upSnap.docs, 450)) {
      final b = _db.batch();
      for (final d in part) {
        b.delete(d.reference);
      }
      await b.commit();
    }

    await _db.doc(FirestorePaths.userDoc(uid)).update({
      'budgets.$categoryId': FieldValue.delete(),
    });
    await _db.doc(FirestorePaths.categoryDoc(uid, categoryId)).delete();
  }

  @override
  Future<void> deleteAccountCascade(String uid, String accountId) async {
    final txCol = _db.collection(FirestorePaths.transactionsCollection(uid));
    final ids = await _collectTransactionIdsForAccountDelete(
      _db,
      uid,
      accountId,
    );
    for (final part in _chunkList(ids.toList(), 450)) {
      final b = _db.batch();
      for (final id in part) {
        b.delete(txCol.doc(id));
      }
      await b.commit();
    }

    Future<void> delRecurring(String field) async {
      final q = await _db
          .collection(FirestorePaths.recurringCollection(uid))
          .where(field, isEqualTo: accountId)
          .get();
      for (final part in _chunkList(q.docs, 450)) {
        final b = _db.batch();
        for (final d in part) {
          b.delete(d.reference);
        }
        await b.commit();
      }
    }

    await delRecurring('accountId');
    await delRecurring('fromAccountId');
    await delRecurring('toAccountId');

    Future<void> delUpcoming(String field) async {
      final q = await _db
          .collection(FirestorePaths.upcomingTransactionsCollection(uid))
          .where(field, isEqualTo: accountId)
          .get();
      for (final part in _chunkList(q.docs, 450)) {
        final b = _db.batch();
        for (final d in part) {
          b.delete(d.reference);
        }
        await b.commit();
      }
    }

    await delUpcoming('accountId');
    await delUpcoming('fromAccountId');
    await delUpcoming('toAccountId');

    await _db.doc(FirestorePaths.accountDoc(uid, accountId)).delete();
  }

  @override
  Future<({int transactions, int recurring, int upcoming})>
  previewCategoryDelete(String uid, String categoryId) async {
    final txCol = _db.collection(FirestorePaths.transactionsCollection(uid));
    final txN = (await txCol.where('categoryId', isEqualTo: categoryId).get())
        .docs
        .length;
    final recCol = _db.collection(FirestorePaths.recurringCollection(uid));
    final recN = (await recCol.where('categoryId', isEqualTo: categoryId).get())
        .docs
        .length;
    final upCol = _db.collection(
      FirestorePaths.upcomingTransactionsCollection(uid),
    );
    final upN = (await upCol.where('categoryId', isEqualTo: categoryId).get())
        .docs
        .length;
    return (transactions: txN, recurring: recN, upcoming: upN);
  }

  @override
  Future<({int transactions, int recurring, int upcoming})>
  previewAccountDelete(String uid, String accountId) async {
    final ids = await _collectTransactionIdsForAccountDelete(
      _db,
      uid,
      accountId,
    );
    final recCol = _db.collection(FirestorePaths.recurringCollection(uid));
    final recIds = <String>{};
    for (final field in ['accountId', 'fromAccountId', 'toAccountId']) {
      final s = await recCol.where(field, isEqualTo: accountId).get();
      for (final d in s.docs) {
        recIds.add(d.id);
      }
    }
    final upCol = _db.collection(
      FirestorePaths.upcomingTransactionsCollection(uid),
    );
    final upIds = <String>{};
    for (final field in ['accountId', 'fromAccountId', 'toAccountId']) {
      final s = await upCol.where(field, isEqualTo: accountId).get();
      for (final d in s.docs) {
        upIds.add(d.id);
      }
    }
    return (
      transactions: ids.length,
      recurring: recIds.length,
      upcoming: upIds.length,
    );
  }
}

final firestoreDataRepositoryProvider = Provider<FirestoreDataRepository>(
  (ref) => FirebaseFirestoreDataRepository(ref.watch(firestoreProvider)),
);
