import 'package:flutter/material.dart';

/// Income and expense sections only; rows are **not** navigation targets.
class FinkoIncomeExpenseAccordion extends StatelessWidget {
  const FinkoIncomeExpenseAccordion({
    super.key,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.incomeAmountText,
    required this.expenseAmountText,
  });

  final String incomeLabel;
  final String expenseLabel;
  final String incomeAmountText;
  final String expenseAmountText;

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
            leading: const Icon(Icons.arrow_downward_rounded),
            title: Text(incomeLabel),
            trailing: Text(incomeAmountText, style: theme.textTheme.titleSmall),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.arrow_upward_rounded),
            title: Text(expenseLabel),
            trailing: Text(
              expenseAmountText,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
