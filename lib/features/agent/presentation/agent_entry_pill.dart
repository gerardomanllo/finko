import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

class AgentEntryPill extends StatelessWidget {
  const AgentEntryPill({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () => context.push('/agent'),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.agentEntryPillLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
