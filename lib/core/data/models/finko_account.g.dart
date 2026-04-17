// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finko_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinkoAccount _$FinkoAccountFromJson(Map<String, dynamic> json) => FinkoAccount(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(
    _$FinkoAccountTypeEnumMap,
    json['type'],
    unknownValue: FinkoAccountType.checking,
  ),
  currency: json['currency'] as String,
  balanceMinor: (json['balanceMinor'] as num).toInt(),
  balanceMinorMain: (json['balanceMinorMain'] as num?)?.toInt(),
  includeInNetCash: json['includeInNetCash'] as bool,
  sortOrder: (json['sortOrder'] as num).toInt(),
  createdAt: const FirestoreUtcDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreUtcDateTimeConverter().fromJson(json['updatedAt']),
  iconKey: json['iconKey'] as String? ?? 'account_balance',
  colorArgb: (json['colorArgb'] as num?)?.toInt(),
);

Map<String, dynamic> _$FinkoAccountToJson(FinkoAccount instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': _$FinkoAccountTypeEnumMap[instance.type]!,
      'currency': instance.currency,
      'balanceMinor': instance.balanceMinor,
      'balanceMinorMain': ?instance.balanceMinorMain,
      'includeInNetCash': instance.includeInNetCash,
      'sortOrder': instance.sortOrder,
      'createdAt': ?const FirestoreUtcDateTimeConverter().toJson(
        instance.createdAt,
      ),
      'updatedAt': ?const FirestoreUtcDateTimeConverter().toJson(
        instance.updatedAt,
      ),
      'iconKey': instance.iconKey,
      'colorArgb': ?instance.colorArgb,
    };

const _$FinkoAccountTypeEnumMap = {
  FinkoAccountType.checking: 'checking',
  FinkoAccountType.savings: 'savings',
  FinkoAccountType.investment: 'investment',
  FinkoAccountType.creditCard: 'creditCard',
  FinkoAccountType.loan: 'loan',
  FinkoAccountType.mortgage: 'mortgage',
};
