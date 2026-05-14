import 'package:flutter/material.dart';

import '../../core/theme/finko_theme.dart';

/// Two rows: this week (top) and next week (bottom).
///
/// Days in [incomeDays] show a small **green** dot; days in [expenseDays] a
/// **blue** (primary) dot. When a day has both, two dots are shown side by side.
class FinkoTwoWeekCalendar extends StatelessWidget {
  const FinkoTwoWeekCalendar({
    super.key,
    required this.weekStart,
    required this.incomeDays,
    required this.expenseDays,
    required this.thisWeekLabel,
    required this.nextWeekLabel,
  });

  /// Monday (or locale week start) of the visible window.
  final DateTime weekStart;
  final Set<String> incomeDays;
  final Set<String> expenseDays;
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
      incomeDays: incomeDays,
      expenseDays: expenseDays,
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
    required this.incomeDays,
    required this.expenseDays,
    required this.theme,
  });

  final String thisWeekLabel;
  final String nextWeekLabel;
  final List<DateTime> thisWeekDays;
  final List<DateTime> nextWeekDays;
  final Set<String> incomeDays;
  final Set<String> expenseDays;
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
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
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
              incomeDays: incomeDays,
              expenseDays: expenseDays,
              keyOf: _key,
            ),
            const SizedBox(height: 16),
            Text(nextWeekLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _WeekRow(
              days: nextWeekDays,
              incomeDays: incomeDays,
              expenseDays: expenseDays,
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
    required this.incomeDays,
    required this.expenseDays,
    required this.keyOf,
  });

  final List<DateTime> days;
  final Set<String> incomeDays;
  final Set<String> expenseDays;
  final String Function(DateTime d) keyOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<FinkoSemanticColors>();
    final incomeColor = semantic?.income ?? FinkoColors.income;
    final expenseColor = theme.colorScheme.primary;
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Column(
              children: [
                Text('${d.day}', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                _DayFlowDots(
                  dayKey: keyOf(d),
                  incomeDays: incomeDays,
                  expenseDays: expenseDays,
                  incomeColor: incomeColor,
                  expenseColor: expenseColor,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayFlowDots extends StatelessWidget {
  const _DayFlowDots({
    required this.dayKey,
    required this.incomeDays,
    required this.expenseDays,
    required this.incomeColor,
    required this.expenseColor,
  });

  final String dayKey;
  final Set<String> incomeDays;
  final Set<String> expenseDays;
  final Color incomeColor;
  final Color expenseColor;

  static const double _dotSize = 6;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final hasIncome = incomeDays.contains(dayKey);
    final hasExpense = expenseDays.contains(dayKey);
    if (!hasIncome && !hasExpense) {
      return const SizedBox(height: _dotSize);
    }
    return SizedBox(
      height: _dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasIncome)
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: incomeColor,
                shape: BoxShape.circle,
              ),
            ),
          if (hasIncome && hasExpense) const SizedBox(width: _gap),
          if (hasExpense)
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: expenseColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
