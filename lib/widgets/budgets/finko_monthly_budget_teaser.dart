import 'package:flutter/material.dart';

import 'finko_category_avatar_ring.dart';

/// One cell in the dashboard “this month’s budget” category grid.
typedef FinkoBudgetTeaserCategoryRing = ({
  String categoryId,
  String iconKey,
  int? colorArgb,
  double ringProgress,
  Color ringColor,
});

/// Dashboard monthly budget teaser: left “left for spending” + progress; right 2×3 category rings.
class FinkoMonthlyBudgetTeaser extends StatelessWidget {
  const FinkoMonthlyBudgetTeaser({
    super.key,
    required this.title,
    required this.leftForSpendingLabel,
    required this.leftForSpendingText,
    required this.progress,
    required this.categoryRings,
    this.onTap,
  });

  final String title;
  final String leftForSpendingLabel;
  final String leftForSpendingText;
  final double progress;
  final List<FinkoBudgetTeaserCategoryRing> categoryRings;
  final VoidCallback? onTap;

  static const double _kRingCell = 46;

  Widget _ringAt(int index) {
    if (index >= categoryRings.length) {
      return const SizedBox.shrink();
    }
    final c = categoryRings[index];
    return AspectRatio(
      aspectRatio: 1,
      child: Center(
        child: FinkoCategoryAvatarRing(
          label: '',
          iconKey: c.iconKey,
          categoryId: c.categoryId,
          colorArgb: c.colorArgb,
          progress: c.ringProgress,
          ringColor: c.ringColor,
          cellSize: _kRingCell,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leftForSpendingLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          leftForSpendingText,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: _ringAt(i),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            for (var i = 3; i < 6; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: _ringAt(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
