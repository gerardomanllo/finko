import 'package:flutter/material.dart';

import '../../domain/agent_message.dart';
import 'agent_action_chips.dart';

class AgentMessageBubble extends StatelessWidget {
  const AgentMessageBubble({
    super.key,
    required this.message,
    required this.onAction,
    this.actionsEnabled = true,
  });

  final AgentMessage message;
  final ValueChanged<String> onAction;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final text = message.text?.trim() ?? '';

    if (text.isEmpty && message.actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (text.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.82,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(text, style: theme.textTheme.bodyLarge),
                ),
              ),
            ),
          if (message.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            AgentActionChips(
              actions: message.actions,
              onAction: onAction,
              enabled: actionsEnabled,
            ),
          ],
        ],
      ),
    );
  }
}
