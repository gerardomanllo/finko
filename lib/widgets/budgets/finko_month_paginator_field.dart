import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Month navigation: calendar icon, center month label, prev/next — no date picker.
class FinkoMonthPaginatorField extends StatelessWidget {
  const FinkoMonthPaginatorField({
    super.key,
    required this.month,
    required this.thisMonthLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final String thisMonthLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    final label = isCurrent
        ? thisMonthLabel
        : DateFormat.yMMMM(locale).format(month);
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
