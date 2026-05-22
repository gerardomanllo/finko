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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((a) {
        return ActionChip(
          label: Text(a.label),
          onPressed: enabled ? () => onAction(a.callbackCode) : null,
        );
      }).toList(),
    );
  }
}
