import 'package:flutter/material.dart';

/// Vertical card for horizontal carousel: avatar, name, bold amount, footer “days until”.
class FinkoUpcomingTransactionCard extends StatelessWidget {
  const FinkoUpcomingTransactionCard({
    super.key,
    required this.title,
    required this.amountText,
    required this.footerText,
    this.secondaryAmountText,
    this.avatarLetter,
  });

  final String title;
  final String amountText;
  final String? secondaryAmountText;
  final String footerText;
  final String? avatarLetter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = (avatarLetter ?? title).trim();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(
                  letter.isNotEmpty ? letter[0].toUpperCase() : '?',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              Text(
                amountText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (secondaryAmountText != null) ...[
                const SizedBox(height: 2),
                Text(
                  secondaryAmountText!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                footerText,
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
