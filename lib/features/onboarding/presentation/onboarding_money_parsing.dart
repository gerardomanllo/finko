/// Parses user money input into minor units (e.g. centavos). Accepts `1234.56` or `1234,56`.
int? parseMajorToMinor(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 0;
  final normalized = trimmed.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) return null;
  return (value * 100).round();
}

/// Display string for amount fields: no decimals when the value is a whole major unit.
String formatMinorAsInputString(int minor) {
  if (minor == 0) return '';
  if (minor % 100 == 0) return '${minor ~/ 100}';
  return (minor / 100).toStringAsFixed(2);
}
