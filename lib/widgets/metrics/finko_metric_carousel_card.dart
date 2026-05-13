import 'package:flutter/material.dart';

/// Top-left label, large value, top-right period delta; optional chart body; tappable.
///
/// When [expandChartVertically] is true, the chart sits in an [Expanded] slot so a
/// [footer] stays at the **bottom** of a **height-bounded** parent (e.g. carousel page);
/// the chart grows to fill space above the footer (no empty “dead” band). When [footer]
/// is null, the same bottom slot height is kept so paired carousel cards stay aligned.
class FinkoMetricCarouselCard extends StatelessWidget {
  const FinkoMetricCarouselCard({
    super.key,
    required this.label,
    required this.valueText,
    this.deltaText,
    required this.chart,
    this.footer,
    this.expandChartVertically = false,
    this.onTap,
  });

  final String label;
  final String valueText;
  final String? deltaText;
  final Widget chart;
  final Widget? footer;

  /// Chart fills all space between the value row and the bottom slot (footer or reserve).
  final bool expandChartVertically;

  final VoidCallback? onTap;

  /// Bottom strip: footer row or empty reserve (paired carousel cards share height).
  static const double _bottomSlotHeight = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (deltaText != null)
                    Text(
                      deltaText!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                valueText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (expandChartVertically) ...[
                Expanded(child: chart),
                const SizedBox(height: 8),
                SizedBox(
                  height: _bottomSlotHeight,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: footer ?? const SizedBox.shrink(),
                  ),
                ),
              ] else ...[
                SizedBox(height: 96, child: chart),
                if (footer != null) ...[const SizedBox(height: 8), footer!],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
