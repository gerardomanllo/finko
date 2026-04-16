import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../json/json_converters.dart';
import 'finko_enums.dart';

part 'ledger_transaction.g.dart';

/// `users/{uid}/transactions/{txId}` — canonical ledger row.
///
/// Named [LedgerTransaction] to avoid clashing with Firestore batch [Transaction].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.transactionDate,
    required this.loadedAt,
    required this.amountMinor,
    required this.direction,
    required this.currency,
    required this.accountId,
    this.categoryId,
    required this.type,
    this.memo,
    this.transferGroupId,
    this.linkedTransactionId,
    this.sourceUpcomingId,
    this.amountMinorMain,
    this.fxRateDateUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Document id only; not stored in the Firestore payload.
  @JsonKey(includeToJson: false)
  final String id;

  /// Business day only, `"yyyy-MM-dd"`.
  final String transactionDate;

  @FirestoreUtcDateTimeConverter()
  final DateTime loadedAt;

  final int amountMinor;

  @JsonKey(unknownEnumValue: MoneyDirection.out_)
  final MoneyDirection direction;

  final String currency;
  final String accountId;
  final String? categoryId;

  @JsonKey(name: 'type', unknownEnumValue: LedgerTransactionKind.standard)
  final LedgerTransactionKind type;

  final String? memo;
  final String? transferGroupId;
  final String? linkedTransactionId;
  final String? sourceUpcomingId;
  final int? amountMinorMain;
  final String? fxRateDateUsed;

  @FirestoreUtcDateTimeConverter()
  final DateTime createdAt;

  @FirestoreUtcDateTimeConverter()
  final DateTime updatedAt;

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) =>
      _$LedgerTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$LedgerTransactionToJson(this);

  factory LedgerTransaction.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return LedgerTransaction.fromJson({...data, 'id': id});
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
