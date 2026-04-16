import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../json/json_converters.dart';
import 'finko_enums.dart';

part 'recurring_rule.g.dart';

/// `users/{uid}/recurring/{ruleId}` — locked schema in `docs/data-model.md` §9.
///
/// **kind** uses the same wire values as [UpcomingKind] and `upcomingTransactions` (§8).
/// **`direction`** replaces a separate income flag (`direction == in` for income).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.name,
    required this.kind,
    required this.amountMinor,
    required this.direction,
    required this.currency,
    this.categoryId,
    this.memo,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    required this.cadence,
    this.daysOfMonth,
    required this.active,
    required this.nextTransactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  @JsonKey(includeToJson: false)
  final String id;

  final String name;

  /// Same discriminator as `upcomingTransactions.kind` (`standard` \| `transfer`).
  @JsonKey(unknownEnumValue: UpcomingKind.standard)
  final UpcomingKind kind;

  final int amountMinor;

  @JsonKey(unknownEnumValue: MoneyDirection.out_)
  final MoneyDirection direction;
  final String currency;
  final String? categoryId;
  final String? memo;

  /// Posting account when [kind] is [UpcomingKind.standard].
  final String? accountId;

  /// When [kind] is [UpcomingKind.transfer], source / destination accounts.
  final String? fromAccountId;
  final String? toAccountId;

  @JsonKey(unknownEnumValue: RecurringCadence.monthly)
  final RecurringCadence cadence;

  /// Calendar days 1–31 for monthly / twice-monthly schedules (e.g. 1st and 15th).
  final List<int>? daysOfMonth;

  @JsonKey(defaultValue: true)
  final bool active;

  /// Next effective business date `"yyyy-MM-dd"`.
  final String nextTransactionDate;

  @FirestoreUtcDateTimeConverter()
  final DateTime createdAt;

  @FirestoreUtcDateTimeConverter()
  final DateTime updatedAt;

  factory RecurringRule.fromJson(Map<String, dynamic> json) =>
      _$RecurringRuleFromJson(json);

  Map<String, dynamic> toJson() => _$RecurringRuleToJson(this);

  /// Normalizes legacy `isIncome` when `direction` is absent.
  factory RecurringRule.fromFirestore(String id, Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    if (!copy.containsKey('direction')) {
      final isIncome = copy['isIncome'];
      if (isIncome == true) {
        copy['direction'] = 'in';
      } else if (copy.containsKey('isIncome')) {
        copy['direction'] = 'out';
      }
    }
    return RecurringRule.fromJson({...copy, 'id': id});
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
