import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../json/json_converters.dart';

part 'processed_aggregate_event.g.dart';

/// `users/{uid}/_processedAggregateEvents/{eventId}` — CF idempotency marker.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ProcessedAggregateEvent {
  const ProcessedAggregateEvent({required this.eventId, this.createdAt});

  @JsonKey(includeToJson: false)
  final String eventId;

  @FirestoreNullableUtcDateTimeConverter()
  final DateTime? createdAt;

  factory ProcessedAggregateEvent.fromJson(Map<String, dynamic> json) =>
      _$ProcessedAggregateEventFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessedAggregateEventToJson(this);

  factory ProcessedAggregateEvent.fromFirestore(
    String eventId,
    Map<String, dynamic> data,
  ) {
    return ProcessedAggregateEvent.fromJson({...data, 'eventId': eventId});
  }

  /// Clients should not write this collection; shape matches Functions / Admin SDK.
  Map<String, dynamic> toFirestore({bool useServerTimestamp = false}) {
    final map = Map<String, dynamic>.from(toJson());
    if (useServerTimestamp) {
      map['createdAt'] = FieldValue.serverTimestamp();
    } else if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!.toUtc());
    }
    return map;
  }
}
