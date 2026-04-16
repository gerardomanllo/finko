// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerTransaction _$LedgerTransactionFromJson(
  Map<String, dynamic> json,
) => LedgerTransaction(
  id: json['id'] as String,
  transactionDate: json['transactionDate'] as String,
  loadedAt: const FirestoreUtcDateTimeConverter().fromJson(json['loadedAt']),
  amountMinor: (json['amountMinor'] as num).toInt(),
  direction: $enumDecode(
    _$MoneyDirectionEnumMap,
    json['direction'],
    unknownValue: MoneyDirection.out_,
  ),
  currency: json['currency'] as String,
  accountId: json['accountId'] as String,
  categoryId: json['categoryId'] as String?,
  type: $enumDecode(
    _$LedgerTransactionKindEnumMap,
    json['type'],
    unknownValue: LedgerTransactionKind.standard,
  ),
  memo: json['memo'] as String?,
  transferGroupId: json['transferGroupId'] as String?,
  linkedTransactionId: json['linkedTransactionId'] as String?,
  sourceUpcomingId: json['sourceUpcomingId'] as String?,
  amountMinorMain: (json['amountMinorMain'] as num?)?.toInt(),
  fxRateDateUsed: json['fxRateDateUsed'] as String?,
  createdAt: const FirestoreUtcDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreUtcDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$LedgerTransactionToJson(
  LedgerTransaction instance,
) => <String, dynamic>{
  'transactionDate': instance.transactionDate,
  'loadedAt': ?const FirestoreUtcDateTimeConverter().toJson(instance.loadedAt),
  'amountMinor': instance.amountMinor,
  'direction': _$MoneyDirectionEnumMap[instance.direction]!,
  'currency': instance.currency,
  'accountId': instance.accountId,
  'categoryId': ?instance.categoryId,
  'type': _$LedgerTransactionKindEnumMap[instance.type]!,
  'memo': ?instance.memo,
  'transferGroupId': ?instance.transferGroupId,
  'linkedTransactionId': ?instance.linkedTransactionId,
  'sourceUpcomingId': ?instance.sourceUpcomingId,
  'amountMinorMain': ?instance.amountMinorMain,
  'fxRateDateUsed': ?instance.fxRateDateUsed,
  'createdAt': ?const FirestoreUtcDateTimeConverter().toJson(
    instance.createdAt,
  ),
  'updatedAt': ?const FirestoreUtcDateTimeConverter().toJson(
    instance.updatedAt,
  ),
};

const _$MoneyDirectionEnumMap = {
  MoneyDirection.in_: 'in',
  MoneyDirection.out_: 'out',
};

const _$LedgerTransactionKindEnumMap = {
  LedgerTransactionKind.standard: 'standard',
  LedgerTransactionKind.transferLeg: 'transferLeg',
  LedgerTransactionKind.adjustment: 'adjustment',
};
