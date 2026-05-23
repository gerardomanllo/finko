import 'package:flutter/material.dart';

import '../../domain/agent_message.dart';

class AgentActionChips extends StatelessWidget {
  const AgentActionChips({
    super.key,
    required this.actions,
    required this.onAction,
    this.enabled = true,
  });

  final List<AgentActionChip> actions;
  final ValueChanged<String> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((a) {
        final isConfirm = a.callbackCode == 'cf';
        final isCancel = a.callbackCode == 'cx' || a.callbackCode == 'rn';

        if (isConfirm) {
          return FilledButton(
            onPressed: enabled ? () => onAction(a.callbackCode) : null,
            child: Text(a.label == '✓' ? '✓' : a.label),
          );
        }
        if (isCancel) {
          return OutlinedButton(
            onPressed: enabled ? () => onAction(a.callbackCode) : null,
            child: Text(a.label == '✗' ? '✗' : a.label),
          );
        }

        return Material(
          color: theme.colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: InkWell(
            onTap: enabled ? () => onAction(a.callbackCode) : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(a.label, style: theme.textTheme.labelLarge),
            ),
          ),
        );
      }).toList(),
    );
  }
}
