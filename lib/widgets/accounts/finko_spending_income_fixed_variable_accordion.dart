import 'package:flutter/material.dart';

/// Spending summary: **income**, **fixed expense**, **variable expense** in one card
/// ([`docs/spending.md`]); rows are **not** navigation targets.
class FinkoSpendingIncomeFixedVariableAccordion extends StatelessWidget {
  const FinkoSpendingIncomeFixedVariableAccordion({
    super.key,
    required this.incomeLabel,
    required this.fixedLabel,
    required this.variableLabel,
    required this.incomeAmountText,
    required this.fixedAmountText,
    required this.variableAmountText,
  });

  final String incomeLabel;
  final String fixedLabel;
  final String variableLabel;
  final String incomeAmountText;
  final String fixedAmountText;
  final String variableAmountText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_downward_rounded),
            title: Text(incomeLabel),
            trailing: Text(incomeAmountText, style: theme.textTheme.titleSmall),
          ),
          const Divider(height: 1),
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
