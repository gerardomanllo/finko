import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../json/json_converters.dart';
import 'finko_enums.dart';

part 'upcoming_transaction.g.dart';

/// `users/{uid}/upcomingTransactions/{id}` — scheduled posting row.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpcomingTransaction {
  const UpcomingTransaction({
    required this.id,
    required this.transactionDate,
    required this.kind,
    required this.amountMinor,
    required this.direction,
    required this.currency,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.transferGroupId,
    this.categoryId,
    this.memo,
    this.recurringRuleId,
    this.cadence,
    this.amountMinorMain,
    this.fxRateDateUsed,
    required this.loadedAt,
    required this.updatedAt,
  });

  @JsonKey(includeToJson: false)
  final String id;

  final String transactionDate;

  @JsonKey(unknownEnumValue: UpcomingKind.standard)
  final UpcomingKind kind;

  final int amountMinor;

  @JsonKey(unknownEnumValue: MoneyDirection.out_)
  final MoneyDirection direction;
  final String currency;
  final String? accountId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? transferGroupId;
  final String? categoryId;
  final String? memo;
  final String? recurringRuleId;
  final String? cadence;

  /// Amount in the user’s main currency (minor units), when populated by backend.
  final int? amountMinorMain;

  final String? fxRateDateUsed;

  @FirestoreUtcDateTimeConverter()
  final DateTime loadedAt;

  @FirestoreUtcDateTimeConverter()
  final DateTime updatedAt;

  factory UpcomingTransaction.fromJson(Map<String, dynamic> json) =>
      _$UpcomingTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$UpcomingTransactionToJson(this);

  factory UpcomingTransaction.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return UpcomingTransaction.fromJson({...data, 'id': id});
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    final map = Map<String, dynamic>.from(toJson());
    if (useServerTimestamps) {
      map['updatedAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}
