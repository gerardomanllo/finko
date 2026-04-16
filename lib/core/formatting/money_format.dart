import 'package:intl/intl.dart';

/// Formats minor units (e.g. cents) with currency code suffix.
String formatMinorUnits(int minor, String currencyCode, String localeName) {
  final fmt = NumberFormat.currency(
    locale: localeName,
    name: currencyCode,
    symbol: '',
    decimalDigits: 2,
  );
  return '${fmt.format(minor / 100.0).trim()} $currencyCode';
}
