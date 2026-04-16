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
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: onSeeMore,
                child: Text(
                  seeMoreLabel!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
