import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Prefer over `.clamp(0, 1 << 62)`: on Flutter **web**, `1 << 62` is **0**
/// (JavaScript bitwise shifts wrap), so positive amounts clamp to 0.
int nonNegativeMinor(int value) => math.max(0, value);

/// Minimum minor-unit floor (e.g. mini-bar denominators). Prefer over
/// `.clamp(1, 1 << 62)`, which throws `Invalid argument: 1` on web.
int atLeastMinor(int value, int min) => math.max(min, value);

final NumberFormat _moneyWholeFormat = NumberFormat('#,##0', 'en_US');
final NumberFormat _moneyFractionalFormat = NumberFormat('#,##0.00', 'en_US');

/// Formats minor units (e.g. cents) with fixed grouping/decimal separators.
///
/// Output style is always `$1,234` or `$1,234.56` (en_US) regardless of locale.
/// Trailing `.00` is omitted when the fractional part is zero.
String formatMinorUnits(int minor, String currencyCode, String localeName) {
  final fmt = minor.abs() % 100 == 0
      ? _moneyWholeFormat
      : _moneyFractionalFormat;
  return '\$${fmt.format(minor / 100.0)}';
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
