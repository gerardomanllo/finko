import 'dart:math' as math;

/// Parses a user-entered decimal amount into **minor units** (e.g. cents), using [fractionDigits] (default 2).
///
/// Accepts optional grouping commas; empty or invalid input throws [FormatException].
int parseAmountStringToMinorUnits(String raw, {int fractionDigits = 2}) {
  final cleaned = raw.trim().replaceAll(',', '');
  if (cleaned.isEmpty) {
    throw const FormatException('empty');
  }
  final v = double.tryParse(cleaned);
  if (v == null) {
    throw const FormatException('parse');
  }
  if (v <= 0) {
    throw const FormatException('nonPositive');
  }
  final factor = math.pow(10, fractionDigits).toDouble();
  return (v * factor).round();
}
