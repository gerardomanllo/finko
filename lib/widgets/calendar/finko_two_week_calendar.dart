import 'package:flutter/material.dart';

import '../../core/theme/finko_theme.dart';

/// Two rows: this week (top) and next week (bottom); [markedDays] get a dot;
/// [incomeDays] also show a green `$` marker.
class FinkoTwoWeekCalendar extends StatelessWidget {
  const FinkoTwoWeekCalendar({
    super.key,
    required this.weekStart,
    required this.markedDays,
    required this.incomeDays,
    required this.thisWeekLabel,
    required this.nextWeekLabel,
  });

  /// Monday (or locale week start) of the visible window.
  final DateTime weekStart;
  final Set<String> markedDays;
  final Set<String> incomeDays;
  final String thisWeekLabel;
  final String nextWeekLabel;

  List<DateTime> _weekDays(DateTime monday) {
    return List<DateTime>.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monday = weekStart;
    final thisWeek = _weekDays(monday);
    final nextWeek = _weekDays(monday.add(const Duration(days: 7)));

    return FinkoTwoWeekCalendarContent(
      thisWeekLabel: thisWeekLabel,
      nextWeekLabel: nextWeekLabel,
      thisWeekDays: thisWeek,
      nextWeekDays: nextWeek,
      markedDays: markedDays,
      incomeDays: incomeDays,
      theme: theme,
    );
  }
}

/// Split out for testing.
class FinkoTwoWeekCalendarContent extends StatelessWidget {
  const FinkoTwoWeekCalendarContent({
    super.key,
    required this.thisWeekLabel,
    required this.nextWeekLabel,
    required this.thisWeekDays,
    required this.nextWeekDays,
    required this.markedDays,
    required this.incomeDays,
    required this.theme,
  });

  final String thisWeekLabel;
  final String nextWeekLabel;
  final List<DateTime> thisWeekDays;
  final List<DateTime> nextWeekDays;
  final Set<String> markedDays;
  final Set<String> incomeDays;
  final ThemeData theme;

  static String _key(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(thisWeekLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _WeekRow(
              days: thisWeekDays,
              markedDays: markedDays,
              incomeDays: incomeDays,
              keyOf: _key,
            ),
            const SizedBox(height: 16),
            Text(nextWeekLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _WeekRow(
              days: nextWeekDays,
              markedDays: markedDays,
              incomeDays: incomeDays,
              keyOf: _key,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.days,
    required this.markedDays,
    required this.incomeDays,
    required this.keyOf,
  });

  final List<DateTime> days;
  final Set<String> markedDays;
  final Set<String> incomeDays;
  final String Function(DateTime d) keyOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<FinkoSemanticColors>();
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Column(
              children: [
                Text('${d.day}', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (markedDays.contains(keyOf(d)))
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (incomeDays.contains(keyOf(d)))
                      Text(
                        r'$',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              semantic?.income ?? theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
