import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared null-safe readers for Firestore [Map<String, dynamic>] payloads.
int readInt(Map<String, dynamic> data, String key, {int defaultValue = 0}) {
  final v = data[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return defaultValue;
}

int? readIntOrNull(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

String readString(
  Map<String, dynamic> data,
  String key, {
  String defaultValue = '',
}) {
  final v = data[key];
  if (v is String) return v;
  return defaultValue;
}

String? readStringOrNull(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v is String) return v;
  return null;
}

bool readBool(
  Map<String, dynamic> data,
  String key, {
  bool defaultValue = false,
}) {
  final v = data[key];
  if (v is bool) return v;
  return defaultValue;
}

bool? readBoolOrNull(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v is bool) return v;
  return null;
}

Timestamp? readTimestampOrNull(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v is Timestamp) return v;
  return null;
}

DateTime? timestampToUtcDateTime(Timestamp? t) => t?.toDate();

Map<String, dynamic> readMapOrEmpty(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v is Map) {
    return Map<String, dynamic>.from(v);
  }
  return <String, dynamic>{};
}

/// Firestore `array` of integers (e.g. days of month 1–31).
List<int>? readIntListOrNull(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v is! List) return null;
  final out = <int>[];
  for (final e in v) {
    if (e is int) {
      out.add(e);
    } else if (e is num) {
      out.add(e.toInt());
    }
  }
  return out.isEmpty ? null : out;
}

Map<String, int> readStringIntMap(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v is! Map) return <String, int>{};
  final map = Map<String, dynamic>.from(v);
  final out = <String, int>{};
  for (final e in map.entries) {
    final val = e.value;
    if (val is int) {
      out[e.key] = val;
    } else if (val is num) {
      out[e.key] = val.toInt();
    }
  }
  return out;
}
