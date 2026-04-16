import 'package:flutter/material.dart';

/// Two non-interactive rows: fixed vs variable expense ([`docs/spending.md`]).
class FinkoFixedVariableExpenseAccordion extends StatelessWidget {
  const FinkoFixedVariableExpenseAccordion({
    super.key,
    required this.fixedLabel,
    required this.variableLabel,
    required this.fixedAmountText,
    required this.variableAmountText,
  });

  final String fixedLabel;
  final String variableLabel;
  final String fixedAmountText;
  final String variableAmountText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: Text(fixedLabel),
            trailing: Text(fixedAmountText, style: theme.textTheme.titleSmall),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.shuffle_rounded),
            title: Text(variableLabel),
            trailing: Text(
              variableAmountText,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
