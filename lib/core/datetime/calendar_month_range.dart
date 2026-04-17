/// First and last calendar days for [yyyyMm] (`yyyy-MM`), inclusive.
({String startYyyyMmDd, String endYyyyMmDd}) calendarMonthStartEndYyyyMmDd(
  String yyyyMm,
) {
  final parts = yyyyMm.split('-');
  if (parts.length != 2) {
    return (startYyyyMmDd: '$yyyyMm-01', endYyyyMmDd: '$yyyyMm-28');
  }
  final y = int.tryParse(parts[0]) ?? 2000;
  final m = int.tryParse(parts[1]) ?? 1;
  final last = DateTime(y, m + 1, 0);
  final mm = m.toString().padLeft(2, '0');
  final start = '${y.toString().padLeft(4, '0')}-$mm-01';
  final end =
      '${y.toString().padLeft(4, '0')}-$mm-${last.day.toString().padLeft(2, '0')}';
  return (startYyyyMmDd: start, endYyyyMmDd: end);
}
