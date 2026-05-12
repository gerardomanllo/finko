import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Thin ring donut + centered titles + legend on the right ([`docs/spending.md`]).
class FinkoDonutLegendRow {
  const FinkoDonutLegendRow({
    required this.color,
    required this.title,
    required this.valueText,
    this.percentText,
  });

  final Color color;
  final String title;
  final String valueText;
  final String? percentText;
}

class FinkoDonutWithSideLegend extends StatelessWidget {
  const FinkoDonutWithSideLegend({
    super.key,
    required this.sections,
    required this.centerTitle,
    required this.centerSubtitle,
    required this.centerTotal,
    required this.legendRows,
    this.chartSize = 168,
    this.centerSpaceRadius = 58,
    this.sectionsSpace = 1,
  });

  final List<PieChartSectionData> sections;
  final String centerTitle;
  final String centerSubtitle;
  final String centerTotal;
  final List<FinkoDonutLegendRow> legendRows;

  final double chartSize;
  final double centerSpaceRadius;

  /// Gap between pie sections (`0` for a continuous thin ring).
  final double sectionsSpace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final maxLegendWidth = (maxW * 0.42).clamp(140.0, 260.0);
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: chartSize,
                width: chartSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: sectionsSpace,
                        centerSpaceRadius: centerSpaceRadius,
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
                        const SizedBox(height: 2),
                        Text(
                          centerSubtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          centerTotal,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: maxLegendWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final row in legendRows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 3, right: 8),
                              decoration: BoxDecoration(
                                color: row.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.title,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    row.percentText != null
                                        ? '${row.valueText} · ${row.percentText}'
                                        : row.valueText,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
