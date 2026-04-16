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
  cadence: $enumDecodeNullable(
    _$RecurringCadenceEnumMap,
    json['cadence'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  daysOfMonth: (json['daysOfMonth'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  weekday: (json['weekday'] as num?)?.toInt(),
  amountMinorMain: (json['amountMinorMain'] as num?)?.toInt(),
  fxRateDateUsed: json['fxRateDateUsed'] as String?,
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
  'cadence': ?_$RecurringCadenceEnumMap[instance.cadence],
  'daysOfMonth': ?instance.daysOfMonth,
  'weekday': ?instance.weekday,
  'amountMinorMain': ?instance.amountMinorMain,
  'fxRateDateUsed': ?instance.fxRateDateUsed,
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

const _$RecurringCadenceEnumMap = {
  RecurringCadence.monthly: 'monthly',
  RecurringCadence.twiceMonthly: 'twiceMonthly',
  RecurringCadence.biweekly: 'biweekly',
  RecurringCadence.weekly: 'weekly',
};
