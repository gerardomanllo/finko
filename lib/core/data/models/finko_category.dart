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

  factory FinkoCategory.fromJson(Map<String, dynamic> json) =>
      _$FinkoCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$FinkoCategoryToJson(this);

  factory FinkoCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return FinkoCategory.fromJson({...data, 'id': id});
  }
}
