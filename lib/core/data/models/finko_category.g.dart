// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finko_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinkoCategory _$FinkoCategoryFromJson(Map<String, dynamic> json) =>
    FinkoCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: $enumDecode(
        _$CategoryKindEnumMap,
        json['kind'],
        unknownValue: CategoryKind.expense,
      ),
      currency: json['currency'] as String?,
      iconKey: json['iconKey'] as String,
      colorArgb: (json['colorArgb'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$FinkoCategoryToJson(FinkoCategory instance) =>
    <String, dynamic>{
      'name': instance.name,
      'kind': _$CategoryKindEnumMap[instance.kind]!,
      'currency': ?instance.currency,
      'iconKey': instance.iconKey,
      'colorArgb': ?instance.colorArgb,
      'sortOrder': instance.sortOrder,
    };

const _$CategoryKindEnumMap = {
  CategoryKind.income: 'income',
  CategoryKind.expense: 'expense',
};
