import 'package:json_annotation/json_annotation.dart';

import 'finko_enums.dart';

part 'finko_category.g.dart';

/// `users/{uid}/categories/{categoryId}`.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FinkoCategory {
  const FinkoCategory({
    required this.id,
    required this.name,
    required this.kind,
    this.currency,
    required this.iconKey,
    this.colorArgb,
    required this.sortOrder,
    this.isFixedExpense = false,
  });

  @JsonKey(includeToJson: false)
  final String id;

  final String name;

  @JsonKey(unknownEnumValue: CategoryKind.expense)
  final CategoryKind kind;
  final String? currency;
  final String iconKey;
  final int? colorArgb;
  final int sortOrder;

  /// When true and [kind] is [CategoryKind.expense], spend/budget rollups
  /// count this category toward fixed (vs variable) expense analytics.
  @JsonKey(defaultValue: false)
  final bool isFixedExpense;

  factory FinkoCategory.fromJson(Map<String, dynamic> json) =>
      _$FinkoCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$FinkoCategoryToJson(this);

  factory FinkoCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return FinkoCategory.fromJson({...data, 'id': id});
  }
}
