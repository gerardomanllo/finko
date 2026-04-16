// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processed_aggregate_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessedAggregateEvent _$ProcessedAggregateEventFromJson(
  Map<String, dynamic> json,
) => ProcessedAggregateEvent(
  eventId: json['eventId'] as String,
  createdAt: const FirestoreNullableUtcDateTimeConverter().fromJson(
    json['createdAt'],
  ),
);

Map<String, dynamic> _$ProcessedAggregateEventToJson(
  ProcessedAggregateEvent instance,
) => <String, dynamic>{
  'createdAt': ?const FirestoreNullableUtcDateTimeConverter().toJson(
    instance.createdAt,
  ),
};
