import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Donut with colored ring only; white center with title + bold total.
class FinkoDonutRingChart extends StatelessWidget {
  const FinkoDonutRingChart({
    super.key,
    required this.sections,
    required this.centerTitle,
    required this.centerTotal,
    this.size = 200,
  });

  final List<PieChartSectionData> sections;
  final String centerTitle;
  final String centerTotal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 56,
              sections: sections,
              borderData: FlBorderData(show: false),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                centerTotal,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
