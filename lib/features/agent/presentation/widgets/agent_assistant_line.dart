import 'package:flutter/material.dart';

import '../../../../core/theme/finko_theme.dart';
import '../../../../l10n/app_localizations.dart';

class AgentAssistantLine extends StatelessWidget {
  const AgentAssistantLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class AgentDetailRow extends StatelessWidget {
  const AgentDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: (iconColor ?? theme.colorScheme.primary).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AgentDirectionBadge extends StatelessWidget {
  const AgentDirectionBadge({super.key, required this.isIncome});

  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantics = Theme.of(context).extension<FinkoSemanticColors>()!;
    final color = isIncome ? semantics.income : semantics.expense;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              isIncome ? l10n.agentDirectionIncome : l10n.agentDirectionExpense,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
