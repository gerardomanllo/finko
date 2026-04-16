import 'package:timezone/timezone.dart' as tz;

/// Calendar date `yyyy-MM-dd` for the user's business "today".
///
/// When [ianaTimezone] is empty, uses the device's local calendar date from [utcNow].
/// Otherwise interprets [utcNow] in the IANA location (requires [initializeTimeZonesForApp]).
String userCalendarDateYyyyMmDd({
  required DateTime utcNow,
  String? ianaTimezone,
}) {
  final trimmed = ianaTimezone?.trim() ?? '';
  if (trimmed.isEmpty) {
    final local = utcNow.toLocal();
    return _formatYmd(local.year, local.month, local.day);
  }
  try {
    final loc = tz.getLocation(trimmed);
    final z = tz.TZDateTime.from(utcNow.toUtc(), loc);
    return _formatYmd(z.year, z.month, z.day);
  } catch (_) {
    final local = utcNow.toLocal();
    return _formatYmd(local.year, local.month, local.day);
  }
}

String _formatYmd(int y, int m, int d) =>
    '${y.toString().padLeft(4, '0')}-'
    '${m.toString().padLeft(2, '0')}-'
    '${d.toString().padLeft(2, '0')}';

/// Parses [yyyyMmDd] into a UTC [DateTime] at midnight **calendar** date (no TZ shift).
DateTime parseYyyyMmDdUtc(String yyyyMmDd) {
  final parts = yyyyMmDd.split('-');
  if (parts.length != 3) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);
  return DateTime.utc(y, m, d);
}

/// Local calendar date only (for weekday / Monday-of-week math).
DateTime parseYyyyMmDdLocal(String yyyyMmDd) {
  final parts = yyyyMmDd.split('-');
  if (parts.length != 3) {
    return DateTime(1970);
  }
  final y = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final d = int.parse(parts[2]);
  return DateTime(y, m, d);
}

/// Days from [fromYyyyMmDd] to [toYyyyMmDd] (can be negative).
int daysBetweenYyyyMmDd(String fromYyyyMmDd, String toYyyyMmDd) {
  final a = parseYyyyMmDdUtc(fromYyyyMmDd);
  final b = parseYyyyMmDdUtc(toYyyyMmDd);
  return b.difference(a).inDays;
}
