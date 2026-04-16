import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ledger_transaction.dart';

/// Client-side maps for `users/{uid}/transactions` — omits server-owned audit fields
/// ([`aggregateApplied`], [`amountMinorMain`], [`fxRateDateUsed`]) so Cloud Functions can set them.
/// See [`docs/data-model.md`] §4.
Map<String, dynamic> ledgerTransactionCreateMap(LedgerTransaction t) {
  final m = <String, dynamic>{
    'transactionDate': t.transactionDate,
    'loadedAt': FieldValue.serverTimestamp(),
    'amountMinor': t.amountMinor,
    'direction': t.direction.wireName,
    'currency': t.currency,
    'accountId': t.accountId,
    'type': t.type.wireName,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (t.categoryId != null) m['categoryId'] = t.categoryId;
  if (t.memo != null && t.memo!.trim().isNotEmpty) {
    m['memo'] = t.memo!.trim();
  }
  if (t.transferGroupId != null && t.transferGroupId!.isNotEmpty) {
    m['transferGroupId'] = t.transferGroupId;
  }
  if (t.linkedTransactionId != null && t.linkedTransactionId!.isNotEmpty) {
    m['linkedTransactionId'] = t.linkedTransactionId;
  }
  if (t.sourceUpcomingId != null && t.sourceUpcomingId!.isNotEmpty) {
    m['sourceUpcomingId'] = t.sourceUpcomingId;
  }
  return m;
}

/// Partial update map. Omits [`createdAt`] / [`loadedAt`] so existing server values stay unchanged.
Map<String, dynamic> ledgerTransactionUpdateMap(LedgerTransaction t) {
  final m = <String, dynamic>{
    'transactionDate': t.transactionDate,
    'amountMinor': t.amountMinor,
    'direction': t.direction.wireName,
    'currency': t.currency,
    'accountId': t.accountId,
    'type': t.type.wireName,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (t.categoryId != null) {
    m['categoryId'] = t.categoryId;
  } else {
    m['categoryId'] = FieldValue.delete();
  }
  if (t.memo != null && t.memo!.trim().isNotEmpty) {
    m['memo'] = t.memo!.trim();
  } else {
    m['memo'] = FieldValue.delete();
  }
  if (t.transferGroupId != null && t.transferGroupId!.isNotEmpty) {
    m['transferGroupId'] = t.transferGroupId;
  } else {
    m['transferGroupId'] = FieldValue.delete();
  }
  if (t.linkedTransactionId != null && t.linkedTransactionId!.isNotEmpty) {
    m['linkedTransactionId'] = t.linkedTransactionId;
  } else {
    m['linkedTransactionId'] = FieldValue.delete();
  }
  if (t.sourceUpcomingId != null && t.sourceUpcomingId!.isNotEmpty) {
    m['sourceUpcomingId'] = t.sourceUpcomingId;
  } else {
    m['sourceUpcomingId'] = FieldValue.delete();
  }
  return m;
}
