import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatting/money_format.dart';

/// Bar chart for projected savings step: income vs fixed vs variable vs net.
class OnboardingProjectedChart extends StatelessWidget {
  const OnboardingProjectedChart({
    super.key,
    required this.expectedIncomeMinor,
    required this.fixedExpensesMinor,
    required this.variableExpensesMinor,
    required this.projectedSavingsMinor,
    required this.currencyCode,
    required this.localeTag,
    required this.incomeLabel,
    required this.fixedLabel,
    required this.variableLabel,
    required this.netLabel,
  });

  final int expectedIncomeMinor;
  final int fixedExpensesMinor;
  final int variableExpensesMinor;
  final int projectedSavingsMinor;
  final String currencyCode;
  final String localeTag;
  final String incomeLabel;
  final String fixedLabel;
  final String variableLabel;
  final String netLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final income = expectedIncomeMinor / 100.0;
    final fixed = fixedExpensesMinor / 100.0;
    final variable = variableExpensesMinor / 100.0;
    final net = projectedSavingsMinor / 100.0;

    final values = <double>[income, fixed, variable, net];
    final positivePeak = values.map((v) => v > 0 ? v : 0.0).reduce(max);
    final negativePeak = values.map((v) => v < 0 ? v : 0.0).reduce(min);
    final maxY = positivePeak <= 0 ? 1.0 : positivePeak * 1.12;
    final minY = negativePeak >= 0 ? 0.0 : negativePeak * 1.12;

    final colors = <Color>[
      cs.primary,
      cs.error,
      cs.tertiary,
      net >= 0 ? cs.secondary : cs.error,
    ];

    final labels = [incomeLabel, fixedLabel, variableLabel, netLabel];

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: minY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : null,
            getDrawingHorizontalLine: (v) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.45),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value < minY || value > maxY) {
                    return const SizedBox.shrink();
                  }
                  final minor = (value * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      formatMinorUnits(minor, currencyCode, localeTag),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[i],
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < 4; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    fromY: values[i] < 0 ? values[i] : 0,
                    toY: values[i] < 0 ? 0 : values[i],
                    color: colors[i],
                    width: 22,
                    borderRadius: values[i] < 0
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(4),
                          )
                        : const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
