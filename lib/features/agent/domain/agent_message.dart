import 'package:cloud_firestore/cloud_firestore.dart';

class AgentActionChip {
  const AgentActionChip({
    required this.id,
    required this.label,
    required this.callbackCode,
  });

  final String id;
  final String label;
  final String callbackCode;

  factory AgentActionChip.fromMap(Map<String, dynamic> map) {
    return AgentActionChip(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      callbackCode: map['callbackCode'] as String? ?? '',
    );
  }
}

enum AgentMessageStatus { pending, processing, complete, failed, superseded }

class AgentMessage {
  const AgentMessage({
    required this.id,
    required this.role,
    required this.kind,
    this.text,
    this.storagePath,
    this.actions = const [],
    this.status,
    this.statusLabelKey,
    this.errorLabelKey,
    this.dismissedAt,
    this.createdAt,
    this.clientMessageId,
  });

  final String id;
  final String role;
  final String kind;
  final String? text;
  final String? storagePath;
  final List<AgentActionChip> actions;
  final AgentMessageStatus? status;
  final String? statusLabelKey;
  final String? errorLabelKey;
  final DateTime? dismissedAt;
  final DateTime? createdAt;
  final String? clientMessageId;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isProcessing => status == AgentMessageStatus.processing;
  bool get isFailed => status == AgentMessageStatus.failed;
  bool get isDismissed => dismissedAt != null;

  factory AgentMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final actionsRaw = data['actions'];
    final actions = <AgentActionChip>[];
    if (actionsRaw is List) {
      for (final item in actionsRaw) {
        if (item is Map) {
          actions.add(AgentActionChip.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return AgentMessage(
      id: doc.id,
      role: data['role'] as String? ?? 'assistant',
      kind: data['kind'] as String? ?? 'text',
      text: data['text'] as String?,
      storagePath: data['storagePath'] as String?,
      actions: actions,
      status: _statusFromWire(data['status'] as String?),
      statusLabelKey: data['statusLabelKey'] as String?,
      errorLabelKey: data['errorLabelKey'] as String?,
      dismissedAt: (data['dismissedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      clientMessageId: data['clientMessageId'] as String?,
    );
  }

  static AgentMessageStatus? _statusFromWire(String? wire) {
    switch (wire) {
      case 'pending':
        return AgentMessageStatus.pending;
      case 'processing':
        return AgentMessageStatus.processing;
      case 'complete':
        return AgentMessageStatus.complete;
      case 'failed':
        return AgentMessageStatus.failed;
      case 'superseded':
        return AgentMessageStatus.superseded;
      default:
        return null;
    }
  }
}
