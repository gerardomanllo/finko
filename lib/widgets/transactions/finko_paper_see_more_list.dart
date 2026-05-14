import 'package:flutter/material.dart';

import '../surfaces/finko_paper_card.dart';

/// Paper-style list with optional final “see more” row.
class FinkoPaperSeeMoreList extends StatelessWidget {
  const FinkoPaperSeeMoreList({
    super.key,
    required this.children,
    this.seeMoreLabel,
    this.onSeeMore,
  });

  final List<Widget> children;
  final String? seeMoreLabel;
  final VoidCallback? onSeeMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FinkoPaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          if (seeMoreLabel != null && onSeeMore != null) ...[
            const Divider(height: 24),
            InkWell(
              onTap: onSeeMore,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        seeMoreLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
