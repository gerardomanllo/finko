import 'package:flutter/material.dart';

import '../../domain/agent_message.dart';
import '../../domain/agent_message_presentation.dart';
import 'agent_action_chips.dart';
import 'agent_assistant_line.dart';
import 'agent_user_utterance.dart';

/// Plain assistant / user rows outside the live transaction flow.
class AgentThreadItem extends StatelessWidget {
  const AgentThreadItem({
    super.key,
    required this.message,
    required this.onAction,
    this.actionsEnabled = true,
    this.sending = false,
    this.animateUser = true,
  });

  final AgentMessage message;
  final ValueChanged<String> onAction;
  final bool actionsEnabled;
  final bool sending;
  final bool animateUser;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      final text = message.text?.trim() ?? '';
      if (text.isEmpty) return const SizedBox.shrink();
      return AgentUserUtterance(
        text: text,
        sending: sending,
        animate: animateUser,
      );
    }

    final presentation = resolveAgentPresentation(message);
    final text = message.text?.trim() ?? '';

    if (presentation.kind == AgentPresentationKind.assistantText &&
        text.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AgentAssistantLine(text: text),
          if (message.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            AgentActionChips(
              actions: message.actions,
              onAction: onAction,
              enabled: actionsEnabled,
            ),
          ],
        ],
      );
    }

    if (message.actions.isNotEmpty) {
      return AgentActionChips(
        actions: message.actions,
        onAction: onAction,
        enabled: actionsEnabled,
      );
    }

    return const SizedBox.shrink();
  }
}
