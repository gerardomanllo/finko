import 'package:flutter/material.dart';

import '../../core/theme/finko_theme.dart';

/// Compact budget tile: **icon**, **title**, **amount** (bold) + **caption** beneath,
/// thin **pill progress** bar, single **footer** line (e.g. paid / earned).
///
/// Typography is intentionally **compact** for the two small `/budgets` tiles.
class FinkoBudgetCompactSummaryCard extends StatelessWidget {
  const FinkoBudgetCompactSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.primaryAmountText,
    required this.primaryCaptionText,
    required this.progress,
    required this.footerText,
  });

  final IconData icon;
  final String title;
  final String primaryAmountText;
  final String primaryCaptionText;
  final double progress;
  final String footerText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: onSurface),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              primaryAmountText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              primaryCaptionText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: FinkoColors.grayLight,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              footerText,
              style: theme.textTheme.labelSmall?.copyWith(color: onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
