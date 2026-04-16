import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// ~30 day series inside a metric card.
class FinkoNetWorthSparkline extends StatelessWidget {
  const FinkoNetWorthSparkline({
    super.key,
    required this.values,
    this.lineColor,
  });

  final List<double> values;
  final Color? lineColor;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final color = lineColor ?? theme.colorScheme.primary;
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.1 + 1;
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
