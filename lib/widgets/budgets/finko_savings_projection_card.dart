import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Left: projected savings text; right: single column bar vs target.
class FinkoSavingsProjectionCard extends StatelessWidget {
  const FinkoSavingsProjectionCard({
    super.key,
    required this.title,
    required this.projectedAmountText,
    required this.targetAmountText,
    required this.projectedFraction,
  });

  final String title;
  final String projectedAmountText;
  final String targetAmountText;
  final double projectedFraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = projectedFraction.clamp(0.0, 1.0);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    projectedAmountText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(targetAmountText, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              height: 120,
              child: BarChart(
                BarChartData(
                  maxY: 1,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: p,
                          width: 36,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
