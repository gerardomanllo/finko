// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_totals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthlyTotals _$MonthlyTotalsFromJson(Map<String, dynamic> json) =>
    MonthlyTotals(
      yearMonth: json['yearMonth'] as String,
      updatedAt: const FirestoreNullableUtcDateTimeConverter().fromJson(
        json['updatedAt'],
      ),
      incomeMinorMain: _rollupMinorFromJson(json['incomeMinorMain']),
      expenseMinorMain: _rollupMinorFromJson(json['expenseMinorMain']),
      byCategoryMinorMain: Map<String, int>.from(
        json['byCategoryMinorMain'] as Map,
      ),
      days: _daysFromJson(json['days']),
    );

Map<String, dynamic> _$MonthlyTotalsToJson(MonthlyTotals instance) =>
    <String, dynamic>{
      'yearMonth': instance.yearMonth,
      'updatedAt': ?const FirestoreNullableUtcDateTimeConverter().toJson(
        instance.updatedAt,
      ),
      'incomeMinorMain': instance.incomeMinorMain,
      'expenseMinorMain': instance.expenseMinorMain,
      'byCategoryMinorMain': instance.byCategoryMinorMain,
      'days': _daysToJson(instance.days),
    };

MonthlyBudgetEntry _$MonthlyBudgetEntryFromJson(Map<String, dynamic> json) =>
    MonthlyBudgetEntry(
      targetMinorMain: (json['targetMinorMain'] as num).toInt(),
      kind: $enumDecode(
        _$BudgetKindEnumMap,
        json['kind'],
        unknownValue: BudgetKind.expense,
      ),
    );

Map<String, dynamic> _$MonthlyBudgetEntryToJson(MonthlyBudgetEntry instance) =>
    <String, dynamic>{
      'targetMinorMain': instance.targetMinorMain,
      'kind': _$BudgetKindEnumMap[instance.kind]!,
    };

const _$BudgetKindEnumMap = {
  BudgetKind.income: 'income',
  BudgetKind.expense: 'expense',
};
