import 'package:intl/intl.dart';

final NumberFormat _moneyWholeFormat = NumberFormat('#,##0', 'en_US');
final NumberFormat _moneyFractionalFormat = NumberFormat('#,##0.00', 'en_US');

/// Formats minor units (e.g. cents) with fixed grouping/decimal separators.
///
/// Output style is always `1,234` or `1,234.56` (en_US) regardless of locale.
/// Trailing `.00` is omitted when the fractional part is zero.
String formatMinorUnits(int minor, String currencyCode, String localeName) {
  final fmt = minor.abs() % 100 == 0
      ? _moneyWholeFormat
      : _moneyFractionalFormat;
  return fmt.format(minor / 100.0);
}

/// Formats minor units and appends currency code (for non-main currency labels).
String formatMinorUnitsWithCode(
  int minor,
  String currencyCode,
  String localeName,
) {
  final amount = formatMinorUnits(minor, currencyCode, localeName);
  return '$amount $currencyCode';
}
