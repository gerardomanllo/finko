import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Firestore [Timestamp] / JSON ↔ [DateTime] (UTC) for required fields.
///
/// Null or missing values become epoch UTC (matches prior hand-written defaults).
class FirestoreUtcDateTimeConverter
    implements JsonConverter<DateTime, Object?> {
  const FirestoreUtcDateTimeConverter();

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  @override
  DateTime fromJson(Object? json) {
    if (json == null) return _epoch;
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json.toUtc();
    throw ArgumentError(
      'Expected Timestamp or DateTime, got ${json.runtimeType}',
    );
  }

  @override
  Object? toJson(DateTime object) => Timestamp.fromDate(object.toUtc());
}

/// Same as [FirestoreUtcDateTimeConverter] but allows null.
class FirestoreNullableUtcDateTimeConverter
    implements JsonConverter<DateTime?, Object?> {
  const FirestoreNullableUtcDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json.toUtc();
    throw ArgumentError(
      'Expected Timestamp or DateTime, got ${json.runtimeType}',
    );
  }

  @override
  Object? toJson(DateTime? object) =>
      object == null ? null : Timestamp.fromDate(object.toUtc());
}
