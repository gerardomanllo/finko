import 'package:flutter/material.dart';

/// Slightly muted style for currency amount inputs (vs. labels and body text).
TextStyle? onboardingAmountInputStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// Puts the currency code on the **right inside** the field (not as helper text below).
InputDecoration onboardingMoneyDecoration({
  required BuildContext context,
  required String labelText,
  required String currencyCode,
}) {
  return InputDecoration(
    labelText: labelText,
    suffixText: currencyCode,
    suffixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
