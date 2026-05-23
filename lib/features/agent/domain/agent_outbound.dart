import 'agent_message.dart';

/// Optimistic user message shown before Firestore echoes it back.
class AgentOutboundMessage {
  const AgentOutboundMessage({
    required this.clientMessageId,
    required this.text,
    required this.createdAt,
    this.sending = true,
    this.failed = false,
  });

  final String clientMessageId;
  final String text;
  final DateTime createdAt;
  final bool sending;
  final bool failed;

  AgentOutboundMessage copyWith({bool? sending, bool? failed}) {
    return AgentOutboundMessage(
      clientMessageId: clientMessageId,
      text: text,
      createdAt: createdAt,
      sending: sending ?? this.sending,
      failed: failed ?? this.failed,
    );
  }

  AgentMessage toSyntheticMessage() {
    return AgentMessage(
      id: 'local-$clientMessageId',
      role: 'user',
      kind: 'text',
      text: text,
      clientMessageId: clientMessageId,
      createdAt: createdAt,
      status: AgentMessageStatus.complete,
    );
  }
}

List<AgentMessage> mergeAgentMessagesWithOutbound({
  required List<AgentMessage> server,
  required List<AgentOutboundMessage> outbound,
}) {
  if (outbound.isEmpty) return server;

  final ackedIds = server
      .map((m) => m.clientMessageId)
      .whereType<String>()
      .toSet();

  final merged = [...server];
  for (final o in outbound) {
    if (ackedIds.contains(o.clientMessageId)) continue;
    merged.add(o.toSyntheticMessage());
  }

  merged.sort((a, b) {
    final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ta.compareTo(tb);
  });
  return merged;
}

bool isOutboundPending({
  required AgentMessage message,
  required List<AgentOutboundMessage> outbound,
}) {
  final id = message.clientMessageId;
  if (id == null) return false;
  return outbound.any((o) => o.clientMessageId == id && o.sending);
}
