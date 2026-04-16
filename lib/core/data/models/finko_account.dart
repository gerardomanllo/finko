import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../json/json_converters.dart';
import 'finko_enums.dart';

part 'finko_account.g.dart';

/// `users/{uid}/accounts/{accountId}`.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FinkoAccount {
  const FinkoAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balanceMinor,
    this.balanceMinorMain,
    required this.includeInNetCash,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  @JsonKey(includeToJson: false)
  final String id;

  final String name;

  @JsonKey(unknownEnumValue: FinkoAccountType.checking)
  final FinkoAccountType type;
  final String currency;
  final int balanceMinor;
  final int? balanceMinorMain;
  final bool includeInNetCash;
  final int sortOrder;

  @FirestoreUtcDateTimeConverter()
  final DateTime createdAt;

  @FirestoreUtcDateTimeConverter()
  final DateTime updatedAt;

  factory FinkoAccount.fromJson(Map<String, dynamic> json) =>
      _$FinkoAccountFromJson(json);

  Map<String, dynamic> toJson() => _$FinkoAccountToJson(this);

  factory FinkoAccount.fromFirestore(String id, Map<String, dynamic> data) {
    return FinkoAccount.fromJson({...data, 'id': id});
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    final map = Map<String, dynamic>.from(toJson());
    if (useServerTimestamps) {
      map['createdAt'] = FieldValue.serverTimestamp();
      map['updatedAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}
