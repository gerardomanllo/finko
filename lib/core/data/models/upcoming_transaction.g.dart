// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upcoming_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpcomingTransaction _$UpcomingTransactionFromJson(
  Map<String, dynamic> json,
) => UpcomingTransaction(
  id: json['id'] as String,
  transactionDate: json['transactionDate'] as String,
  kind: $enumDecode(
    _$UpcomingKindEnumMap,
    json['kind'],
    unknownValue: UpcomingKind.standard,
  ),
  amountMinor: (json['amountMinor'] as num).toInt(),
  direction: $enumDecode(
    _$MoneyDirectionEnumMap,
    json['direction'],
    unknownValue: MoneyDirection.out_,
  ),
  currency: json['currency'] as String,
  accountId: json['accountId'] as String?,
  fromAccountId: json['fromAccountId'] as String?,
  toAccountId: json['toAccountId'] as String?,
  transferGroupId: json['transferGroupId'] as String?,
  categoryId: json['categoryId'] as String?,
  memo: json['memo'] as String?,
  recurringRuleId: json['recurringRuleId'] as String?,
  cadence: json['cadence'] as String?,
  loadedAt: const FirestoreUtcDateTimeConverter().fromJson(json['loadedAt']),
  updatedAt: const FirestoreUtcDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$UpcomingTransactionToJson(
  UpcomingTransaction instance,
) => <String, dynamic>{
  'transactionDate': instance.transactionDate,
  'kind': _$UpcomingKindEnumMap[instance.kind]!,
  'amountMinor': instance.amountMinor,
  'direction': _$MoneyDirectionEnumMap[instance.direction]!,
  'currency': instance.currency,
  'accountId': ?instance.accountId,
  'fromAccountId': ?instance.fromAccountId,
  'toAccountId': ?instance.toAccountId,
  'transferGroupId': ?instance.transferGroupId,
  'categoryId': ?instance.categoryId,
  'memo': ?instance.memo,
  'recurringRuleId': ?instance.recurringRuleId,
  'cadence': ?instance.cadence,
  'loadedAt': ?const FirestoreUtcDateTimeConverter().toJson(instance.loadedAt),
  'updatedAt': ?const FirestoreUtcDateTimeConverter().toJson(
    instance.updatedAt,
  ),
};

const _$UpcomingKindEnumMap = {
  UpcomingKind.standard: 'standard',
  UpcomingKind.transfer: 'transfer',
};

const _$MoneyDirectionEnumMap = {
  MoneyDirection.in_: 'in',
  MoneyDirection.out_: 'out',
};
