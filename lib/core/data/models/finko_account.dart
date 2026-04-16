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
    int readInt(String key, {int fallback = 0}) {
      final raw = data[key];
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? fallback;
      return fallback;
    }

    DateTime readDate(String key) {
      final raw = data[key];
      if (raw is Timestamp) return raw.toDate().toUtc();
      if (raw is DateTime) return raw.toUtc();
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    final rawType = data['type'] as String?;
    final type =
        FinkoAccountType.tryParse(rawType) ?? FinkoAccountType.checking;

    final includeRaw = data['includeInNetCash'];
    final includeInNetCash = includeRaw is bool
        ? includeRaw
        : (type == FinkoAccountType.checking ||
              type == FinkoAccountType.creditCard);

    return FinkoAccount(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : id,
      type: type,
      currency: ((data['currency'] as String?)?.trim().isNotEmpty == true)
          ? (data['currency'] as String).trim()
          : 'MXN',
      balanceMinor: readInt('balanceMinor'),
      balanceMinorMain: data['balanceMinorMain'] == null
          ? null
          : readInt('balanceMinorMain'),
      includeInNetCash: includeInNetCash,
      sortOrder: readInt('sortOrder', fallback: 0),
      createdAt: readDate('createdAt'),
      updatedAt: readDate('updatedAt'),
    );
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
