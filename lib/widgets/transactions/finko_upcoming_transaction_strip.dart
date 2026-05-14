import 'package:flutter/material.dart';

import '../../core/data/models/finko_category.dart';
import '../categories/finko_category_icon_avatar.dart';

/// Trailing card in the dashboard upcoming row: tap opens the full upcoming list (Recurring tab).
class FinkoUpcomingSeeAllCard extends StatelessWidget {
  const FinkoUpcomingSeeAllCard({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 132,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical card for horizontal carousel: avatar, name, bold amount, footer “days until”.
class FinkoUpcomingTransactionCard extends StatelessWidget {
  const FinkoUpcomingTransactionCard({
    super.key,
    required this.title,
    required this.amountText,
    required this.footerText,
    this.secondaryAmountText,
    this.category,
    this.avatarLetter,
  });

  final String title;
  final String amountText;
  final String? secondaryAmountText;
  final String footerText;

  /// When set, shows category icon + accent; otherwise [avatarLetter] / [title].
  final FinkoCategory? category;
  final String? avatarLetter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = (avatarLetter ?? title).trim();
    final c = category;
    final Widget avatar = c != null
        ? FinkoCategoryIconAvatar.fromCategory(c, radius: 19)
        : CircleAvatar(
            radius: 19,
            child: Text(
              letter.isNotEmpty ? letter[0].toUpperCase() : '?',
              style: theme.textTheme.labelLarge,
            ),
          );
    return SizedBox(
      width: 132,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: avatar),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              Text(
                amountText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (secondaryAmountText != null) ...[
                const SizedBox(height: 2),
                Text(
                  secondaryAmountText!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                footerText,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
