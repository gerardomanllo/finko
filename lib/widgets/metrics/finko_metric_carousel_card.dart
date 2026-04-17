import 'package:flutter/material.dart';

/// Top-left label, large value, top-right period delta; optional chart body; tappable.
class FinkoMetricCarouselCard extends StatelessWidget {
  const FinkoMetricCarouselCard({
    super.key,
    required this.label,
    required this.valueText,
    this.deltaText,
    required this.chart,
    this.onTap,
  });

  final String label;
  final String valueText;
  final String? deltaText;
  final Widget chart;
  final VoidCallback? onTap;

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
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(height: 96, child: chart),
            ],
          ),
        ),
      ),
    );
  }
}
