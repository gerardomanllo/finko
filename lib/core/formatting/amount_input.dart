import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Restricts text to characters accepted by [parseAmountStringToMinorUnits]:
/// digits, optional `,` grouping, a single `.`, and at most [maxFractionDigits]
/// after the decimal (default 2).
class AmountTextInputFormatter extends TextInputFormatter {
  AmountTextInputFormatter({this.maxFractionDigits = 2});

  final int maxFractionDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9.,]'), '');
    final dotIndex = text.indexOf('.');
    if (text.indexOf('.', dotIndex + 1) >= 0) {
      return oldValue;
    }
    if (dotIndex >= 0 && maxFractionDigits >= 0) {
      final frac = text.substring(dotIndex + 1);
      if (frac.length > maxFractionDigits) {
        text = text.substring(0, dotIndex + 1 + maxFractionDigits);
      }
    }
    var offset = newValue.selection.end;
    if (offset > text.length) offset = text.length;
    if (offset < 0) offset = 0;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }
}

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
