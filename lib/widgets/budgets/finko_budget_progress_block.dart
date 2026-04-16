import 'package:flutter/material.dart';

/// Labels for spent / left / budgeted + linear progress.
class FinkoBudgetProgressBlock extends StatelessWidget {
  const FinkoBudgetProgressBlock({
    super.key,
    required this.title,
    required this.leftLabel,
    required this.leftAmountText,
    required this.spentLabel,
    required this.spentAmountText,
    required this.budgetedLabel,
    required this.budgetedAmountText,
    required this.progress,
    this.paceText,
  });

  final String title;
  final String leftLabel;
  final String leftAmountText;
  final String spentLabel;
  final String spentAmountText;
  final String budgetedLabel;
  final String budgetedAmountText;
  final double progress;
  final String? paceText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.trending_flat, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (paceText != null)
                  Text(paceText!, style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(leftLabel, style: theme.textTheme.labelMedium),
            Text(
              leftAmountText,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress.clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$spentLabel $spentAmountText',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  '$budgetedLabel $budgetedAmountText',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
