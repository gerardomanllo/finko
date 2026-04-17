import 'package:json_annotation/json_annotation.dart';

import '../firestore_map_utils.dart';
import '../json/json_converters.dart';
import 'finko_enums.dart';

part 'monthly_totals.g.dart';

/// `users/{uid}/monthlyTotals/{yyyy-mm}` — denormalized month rollup.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MonthlyTotals {
  const MonthlyTotals({
    required this.yearMonth,
    this.updatedAt,
    required this.incomeMinorMain,
    required this.expenseMinorMain,
    required this.byCategoryMinorMain,
    required this.days,
  });

  final String yearMonth;

  @FirestoreNullableUtcDateTimeConverter()
  final DateTime? updatedAt;

  final int incomeMinorMain;
  final int expenseMinorMain;
  final Map<String, int> byCategoryMinorMain;

  @JsonKey(fromJson: _daysFromJson, toJson: _daysToJson)
  final Map<String, MonthlyDayRollup> days;

  factory MonthlyTotals.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTotalsFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyTotalsToJson(this);

  factory MonthlyTotals.fromFirestore(Map<String, dynamic> data) {
    return MonthlyTotals.fromJson(data);
  }

  Map<String, dynamic> toFirestore() {
    return toJson();
  }
}

/// Parses `users/{uid}.budgets` or legacy `monthlyTotals.*.budgets`.
///
/// **Legacy:** flat `categoryId` → minor int coerces to expense targets.
Map<String, MonthlyBudgetEntry> budgetMapFromFirestoreJson(Object? json) {
  if (json is! Map) return {};
  final out = <String, MonthlyBudgetEntry>{};
  for (final e in json.entries) {
    final k = e.key;
    final v = e.value;
    if (k is! String) continue;
    if (v is Map) {
      out[k] = MonthlyBudgetEntry.fromJson(Map<String, dynamic>.from(v));
    } else if (v is num) {
      out[k] = MonthlyBudgetEntry(
        targetMinorMain: v.toInt(),
        kind: BudgetKind.expense,
      );
    }
  }
  return out;
}

Map<String, dynamic> budgetMapToFirestoreJson(
  Map<String, MonthlyBudgetEntry> value,
) {
  return {for (final e in value.entries) e.key: e.value.toJson()};
}

Map<String, MonthlyDayRollup> _daysFromJson(Object? json) {
  if (json is! Map) return {};
  final out = <String, MonthlyDayRollup>{};
  for (final e in json.entries) {
    final k = e.key;
    final v = e.value;
    if (k is! String || v is! Map) continue;
    out[k] = MonthlyDayRollup.fromJson(Map<String, dynamic>.from(v));
  }
  return out;
}

Map<String, dynamic> _daysToJson(Map<String, MonthlyDayRollup> value) {
  return {for (final e in value.entries) e.key: e.value.toJson()};
}

/// One category row under `users/{uid}.budgets.{categoryId}`:
/// `{ targetMinorMain, kind }`.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MonthlyBudgetEntry {
  const MonthlyBudgetEntry({required this.targetMinorMain, required this.kind});

  final int targetMinorMain;

  @JsonKey(unknownEnumValue: BudgetKind.expense)
  final BudgetKind kind;

  factory MonthlyBudgetEntry.fromJson(Map<String, dynamic> json) =>
      _$MonthlyBudgetEntryFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyBudgetEntryToJson(this);
}

/// `days.{dd}` — cashflow and optional end-of-day net worth (main currency).
///
/// Extra keys from Functions are preserved via [extra].
class MonthlyDayRollup {
  const MonthlyDayRollup({
    this.incomeMinorMain,
    this.expenseMinorMain,
    this.netWorthEodMinorMain,
    this.byCategoryMinorMain = const {},
    this.extra = const {},
  });

  final int? incomeMinorMain;
  final int? expenseMinorMain;
  final int? netWorthEodMinorMain;
  final Map<String, int> byCategoryMinorMain;
  final Map<String, dynamic> extra;

  factory MonthlyDayRollup.fromJson(Map<String, dynamic> json) {
    const known = {
      'incomeMinorMain',
      'expenseMinorMain',
      'netWorthEodMinorMain',
      'byCategoryMinorMain',
    };
    final extra = <String, dynamic>{};
    final core = <String, dynamic>{};
    for (final e in json.entries) {
      if (known.contains(e.key)) {
        core[e.key] = e.value;
      } else {
        extra[e.key] = e.value;
      }
    }
    return MonthlyDayRollup(
      incomeMinorMain: readIntOrNull(core, 'incomeMinorMain'),
      expenseMinorMain: readIntOrNull(core, 'expenseMinorMain'),
      netWorthEodMinorMain: readIntOrNull(core, 'netWorthEodMinorMain'),
      byCategoryMinorMain: readStringIntMap(core, 'byCategoryMinorMain'),
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (incomeMinorMain != null) 'incomeMinorMain': incomeMinorMain,
      if (expenseMinorMain != null) 'expenseMinorMain': expenseMinorMain,
      if (netWorthEodMinorMain != null)
        'netWorthEodMinorMain': netWorthEodMinorMain,
      if (byCategoryMinorMain.isNotEmpty)
        'byCategoryMinorMain': byCategoryMinorMain,
      ...extra,
    };
  }
}
