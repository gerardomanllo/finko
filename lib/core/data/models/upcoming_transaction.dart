import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../json/json_converters.dart';
import 'finko_enums.dart';
import 'ledger_transaction.dart';
import 'recurring_rule.dart';

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
    this.daysOfMonth,
    this.weekday,
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

  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final RecurringCadence? cadence;

  /// Mirrors `recurring` / materializer (monthly, twice-monthly).
  final List<int>? daysOfMonth;

  /// Mon=1 … Sun=7 when [cadence] is [RecurringCadence.weekly].
  final int? weekday;

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

  /// Dashboard strip when [RecurringRule.nextTransactionDate] is not yet in
  /// `upcomingTransactions` (e.g. not materialized).
  factory UpcomingTransaction.fromRecurringRulePreview(
    RecurringRule rule, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    return UpcomingTransaction(
      id: 'recurring_preview_${rule.id}',
      transactionDate: rule.nextTransactionDate,
      kind: rule.kind,
      amountMinor: rule.amountMinor,
      direction: rule.direction,
      currency: rule.currency,
      accountId: rule.accountId,
      fromAccountId: rule.fromAccountId,
      toAccountId: rule.toAccountId,
      transferGroupId: null,
      categoryId: rule.categoryId,
      memo: rule.memo ?? rule.name,
      recurringRuleId: rule.id,
      cadence: rule.cadence,
      daysOfMonth: rule.daysOfMonth,
      weekday: rule.weekday,
      amountMinorMain: null,
      fxRateDateUsed: null,
      loadedAt: n,
      updatedAt: n,
    );
  }

  /// Dashboard strip for **future-dated** rows in `transactions/` (not in
  /// `upcomingTransactions`).
  factory UpcomingTransaction.fromLedgerPreview(
    LedgerTransaction t, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    return UpcomingTransaction(
      id: 'ledger_preview_${t.id}',
      transactionDate: t.transactionDate,
      kind: UpcomingKind.standard,
      amountMinor: t.amountMinor,
      direction: t.direction,
      currency: t.currency,
      accountId: t.accountId,
      fromAccountId: null,
      toAccountId: null,
      transferGroupId: t.transferGroupId,
      categoryId: t.categoryId,
      memo: t.memo,
      recurringRuleId: null,
      cadence: null,
      daysOfMonth: null,
      weekday: null,
      amountMinorMain: t.amountMinorMain,
      fxRateDateUsed: t.fxRateDateUsed,
      loadedAt: n,
      updatedAt: n,
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    final map = Map<String, dynamic>.from(toJson());
    if (useServerTimestamps) {
      map['updatedAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}
