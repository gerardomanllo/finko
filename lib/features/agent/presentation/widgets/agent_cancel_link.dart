import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Subtle cancel affordance for agent choice / confirm flows.
class AgentCancelLink extends StatelessWidget {
  const AgentCancelLink({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w400,
          ),
        ),
        child: Text(l10n.agentCancel),
      ),
    );
  }
}
