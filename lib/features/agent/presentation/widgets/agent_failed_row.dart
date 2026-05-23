import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../agent_l10n.dart';

class AgentFailedRow extends StatelessWidget {
  const AgentFailedRow({
    super.key,
    required this.errorLabelKey,
    required this.onDismiss,
    this.onRetry,
  });

  final String? errorLabelKey;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_outlined,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  agentErrorLabel(l10n, errorLabelKey),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
              IconButton(
                tooltip: l10n.agentDismiss,
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
