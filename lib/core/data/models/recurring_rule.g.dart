// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringRule _$RecurringRuleFromJson(
  Map<String, dynamic> json,
) => RecurringRule(
  id: json['id'] as String,
  name: json['name'] as String,
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
  categoryId: json['categoryId'] as String?,
  memo: json['memo'] as String?,
  accountId: json['accountId'] as String?,
  fromAccountId: json['fromAccountId'] as String?,
  toAccountId: json['toAccountId'] as String?,
  cadence: $enumDecode(
    _$RecurringCadenceEnumMap,
    json['cadence'],
    unknownValue: RecurringCadence.monthly,
  ),
  daysOfMonth: (json['daysOfMonth'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  weekday: (json['weekday'] as num?)?.toInt(),
  active: json['active'] as bool? ?? true,
  nextTransactionDate: json['nextTransactionDate'] as String,
  createdAt: const FirestoreUtcDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreUtcDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$RecurringRuleToJson(RecurringRule instance) =>
    <String, dynamic>{
      'name': instance.name,
      'kind': _$UpcomingKindEnumMap[instance.kind]!,
      'amountMinor': instance.amountMinor,
      'direction': _$MoneyDirectionEnumMap[instance.direction]!,
      'currency': instance.currency,
      'categoryId': ?instance.categoryId,
      'memo': ?instance.memo,
      'accountId': ?instance.accountId,
      'fromAccountId': ?instance.fromAccountId,
      'toAccountId': ?instance.toAccountId,
      'cadence': _$RecurringCadenceEnumMap[instance.cadence]!,
      'daysOfMonth': ?instance.daysOfMonth,
      'weekday': ?instance.weekday,
      'active': instance.active,
      'nextTransactionDate': instance.nextTransactionDate,
      'createdAt': ?const FirestoreUtcDateTimeConverter().toJson(
        instance.createdAt,
      ),
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
