import 'agent_message.dart';
import 'agent_message_presentation.dart';

enum AgentFlowPhase { gathering, confirm, sealed, cancelled }

enum AgentFlowFieldKey { amount, memo, category, account, direction }

/// Stored in [_localFlowFields] to override a field with an explicit clear.
const agentLocalFieldCleared = '__cleared__';

/// Cumulative transaction card state built from a message flow + local picks.
class AgentLiveTransactionState {
  const AgentLiveTransactionState({
    this.directionIsIncome,
    this.amount,
    this.memo,
    this.category,
    this.account,
    this.phase = AgentFlowPhase.gathering,
    this.successText,
    this.isTransfer = false,
    this.transfer,
  });

  final bool? directionIsIncome;
  final String? amount;
  final String? memo;
  final String? category;
  final String? account;
  final AgentFlowPhase phase;
  final String? successText;
  final bool isTransfer;
  final AgentTransferPreview? transfer;

  bool get directionKnown => directionIsIncome != null;
  bool get isIncome => directionIsIncome ?? false;

  bool get isSealed =>
      phase == AgentFlowPhase.sealed || phase == AgentFlowPhase.cancelled;

  AgentLiveTransactionState copyWith({
    bool? directionIsIncome,
    String? amount,
    String? memo,
    String? category,
    String? account,
    AgentFlowPhase? phase,
    String? successText,
    bool? isTransfer,
    AgentTransferPreview? transfer,
  }) {
    return AgentLiveTransactionState(
      directionIsIncome: directionIsIncome ?? this.directionIsIncome,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      category: category ?? this.category,
      account: account ?? this.account,
      phase: phase ?? this.phase,
      successText: successText ?? this.successText,
      isTransfer: isTransfer ?? this.isTransfer,
      transfer: transfer ?? this.transfer,
    );
  }

  AgentLiveTransactionState mergeField(AgentFlowFieldKey key, String value) {
    return switch (key) {
      AgentFlowFieldKey.amount => copyWith(amount: value),
      AgentFlowFieldKey.memo => copyWith(memo: value),
      AgentFlowFieldKey.category => copyWith(category: value),
      AgentFlowFieldKey.account => copyWith(account: value),
      AgentFlowFieldKey.direction => copyWith(
        directionIsIncome: value.toUpperCase() == 'IN',
      ),
    };
  }

  AgentLiveTransactionState clearField(AgentFlowFieldKey key) {
    return switch (key) {
      AgentFlowFieldKey.amount => AgentLiveTransactionState(
        directionIsIncome: directionIsIncome,
        memo: memo,
        category: category,
        account: account,
        phase: phase,
        successText: successText,
        isTransfer: isTransfer,
        transfer: transfer,
      ),
      AgentFlowFieldKey.memo => AgentLiveTransactionState(
        directionIsIncome: directionIsIncome,
        amount: amount,
        category: category,
        account: account,
        phase: phase,
        successText: successText,
        isTransfer: isTransfer,
        transfer: transfer,
      ),
      AgentFlowFieldKey.category => AgentLiveTransactionState(
        directionIsIncome: directionIsIncome,
        amount: amount,
        memo: memo,
        account: account,
        phase: phase,
        successText: successText,
        isTransfer: isTransfer,
        transfer: transfer,
      ),
      AgentFlowFieldKey.account => AgentLiveTransactionState(
        directionIsIncome: directionIsIncome,
        amount: amount,
        memo: memo,
        category: category,
        phase: phase,
        successText: successText,
        isTransfer: isTransfer,
        transfer: transfer,
      ),
      AgentFlowFieldKey.direction => AgentLiveTransactionState(
        amount: amount,
        memo: memo,
        category: category,
        account: account,
        phase: phase,
        successText: successText,
        isTransfer: isTransfer,
        transfer: transfer,
      ),
    };
  }
}

class AgentTransactionFlowSegment {
  const AgentTransactionFlowSegment({
    required this.id,
    required this.userMessage,
    required this.assistantMessages,
    required this.state,
    required this.activeMessage,
  });

  final String id;
  final AgentMessage userMessage;
  final List<AgentMessage> assistantMessages;
  final AgentLiveTransactionState state;
  final AgentMessage? activeMessage;
}

sealed class AgentThreadSegment {
  const AgentThreadSegment();
}

class AgentThreadUserSegment extends AgentThreadSegment {
  const AgentThreadUserSegment(this.message);
  final AgentMessage message;
}

class AgentThreadAssistantSegment extends AgentThreadSegment {
  const AgentThreadAssistantSegment(this.message);
  final AgentMessage message;
}

class AgentThreadFlowSegment extends AgentThreadSegment {
  const AgentThreadFlowSegment(this.flow);
  final AgentTransactionFlowSegment flow;
}

List<AgentThreadSegment> segmentAgentThread(List<AgentMessage> messages) {
  final out = <AgentThreadSegment>[];
  var i = 0;
  while (i < messages.length) {
    final m = messages[i];
    if (m.isProcessing) {
      i++;
      continue;
    }
    if (m.isFailed) {
      out.add(AgentThreadAssistantSegment(m));
      i++;
      continue;
    }
    if (_startsTransactionFlow(messages, i)) {
      out.add(AgentThreadUserSegment(messages[i]));
      final flow = _collectFlow(messages, i);
      out.add(AgentThreadFlowSegment(flow));
      i = _indexAfterFlow(messages, i);
      continue;
    }
    if (m.isUser) {
      out.add(AgentThreadUserSegment(m));
    } else if (!_isFlowAssistantMessage(m) || _isTerminalFlowMessage(m)) {
      if (_isTerminalFlowMessage(m)) {
        // Orphan terminal — show as assistant line.
        out.add(AgentThreadAssistantSegment(m));
      } else if (!_isFlowAssistantMessage(m)) {
        out.add(AgentThreadAssistantSegment(m));
      }
    }
    i++;
  }
  return out;
}

bool _startsTransactionFlow(List<AgentMessage> messages, int userIndex) {
  final m = messages[userIndex];
  if (!m.isUser) return false;
  for (var j = userIndex + 1; j < messages.length; j++) {
    final next = messages[j];
    if (next.isUser) return false;
    if (next.isProcessing || next.isFailed) return false;
    if (_isFlowAssistantMessage(next)) return true;
    if (next.text?.trim().isNotEmpty ?? false) return false;
  }
  return false;
}

int _indexAfterFlow(List<AgentMessage> messages, int userIndex) {
  var j = userIndex + 1;
  while (j < messages.length) {
    final m = messages[j];
    if (m.isUser) break;
    if (m.isProcessing || m.isFailed) break;
    if (_isTerminalFlowMessage(m)) return j + 1;
    if (_isFlowAssistantMessage(m)) {
      j++;
      continue;
    }
    break;
  }
  return j;
}

AgentTransactionFlowSegment _collectFlow(
  List<AgentMessage> messages,
  int userIndex,
) {
  final user = messages[userIndex];
  final assistants = <AgentMessage>[];
  var j = userIndex + 1;
  while (j < messages.length) {
    final m = messages[j];
    if (m.isUser || m.isProcessing || m.isFailed) break;
    if (_isTerminalFlowMessage(m)) {
      assistants.add(m);
      break;
    }
    if (_isFlowAssistantMessage(m)) {
      assistants.add(m);
      j++;
      continue;
    }
    break;
  }

  final state = buildLiveTransactionState(user, assistants);
  AgentMessage? active;
  if (!state.isSealed && assistants.isNotEmpty) {
    active = assistants.lastWhere(
      (m) => !_isTerminalFlowMessage(m),
      orElse: () => assistants.last,
    );
    if (_isTerminalFlowMessage(active)) active = null;
  }

  return AgentTransactionFlowSegment(
    id: assistants.isNotEmpty ? assistants.first.id : user.id,
    userMessage: user,
    assistantMessages: assistants,
    state: state,
    activeMessage: active,
  );
}

bool _isFlowAssistantMessage(AgentMessage m) {
  if (!m.isAssistant) return false;
  final codes = m.actions.map((a) => a.callbackCode).toList();
  if (codes.any(
    (c) =>
        c.startsWith('pc:') ||
        c.startsWith('pa:') ||
        c.startsWith('tf:') ||
        c.startsWith('tt:') ||
        const {'rm', 'rt', 'rb', 'rw', 'rn', 'cf', 'cx'}.contains(c),
  )) {
    return true;
  }
  final p = resolveAgentPresentation(m);
  return p.kind == AgentPresentationKind.transactionConfirm ||
      p.kind == AgentPresentationKind.transferConfirm;
}

bool _isTerminalFlowMessage(AgentMessage m) {
  final text = m.text?.trim().toLowerCase() ?? '';
  if (text.isEmpty) return false;
  return _looksPosted(text) || _looksCancelled(text);
}

bool _looksPosted(String lower) =>
    lower.contains('recorded') ||
    lower.contains('registrado') ||
    lower.contains('registered') ||
    lower.startsWith('expense recorded') ||
    lower.startsWith('gasto registrado') ||
    lower.startsWith('income recorded') ||
    lower.contains('ingreso registrado') ||
    lower.contains('transfer recorded') ||
    lower.contains('transferencia');

bool _looksCancelled(String lower) =>
    lower == 'cancelled.' ||
    lower == 'cancelado.' ||
    lower.startsWith('cancelled') ||
    lower.startsWith('cancelado');

AgentLiveTransactionState buildLiveTransactionState(
  AgentMessage userMessage,
  List<AgentMessage> assistantMessages, {
  Map<AgentFlowFieldKey, String> localFields = const {},
}) {
  var state = AgentLiveTransactionState();
  final intent = parseUserTransactionIntent(userMessage.text ?? '');
  if (intent.amount != null) {
    state = state.mergeField(AgentFlowFieldKey.amount, intent.amount!);
  }
  if (intent.memo != null) {
    state = state.mergeField(AgentFlowFieldKey.memo, intent.memo!);
  }
  if (intent.isIncome != null) {
    state = state.copyWith(directionIsIncome: intent.isIncome);
  }

  for (final msg in assistantMessages) {
    state = _mergeAssistantMessage(state, msg, userMessage);
  }

  for (final local in localFields.entries) {
    if (local.value == agentLocalFieldCleared) {
      state = state.clearField(local.key);
    } else {
      state = state.mergeField(local.key, local.value);
    }
  }
  return state;
}

AgentLiveTransactionState _mergeAssistantMessage(
  AgentLiveTransactionState state,
  AgentMessage msg,
  AgentMessage userMessage,
) {
  final text = msg.text?.trim() ?? '';
  if (_isTerminalFlowMessage(msg)) {
    if (_looksCancelled(text.toLowerCase())) {
      return state.copyWith(phase: AgentFlowPhase.cancelled, successText: text);
    }
    return state.copyWith(phase: AgentFlowPhase.sealed, successText: text);
  }

  final amountFromHint = parseAmountHint(text);
  if (amountFromHint != null) {
    state = state.mergeField(AgentFlowFieldKey.amount, amountFromHint);
  }

  final presentation = resolveAgentPresentation(msg);
  if (presentation.kind == AgentPresentationKind.transactionConfirm &&
      presentation.transaction != null) {
    final t = presentation.transaction!;
    return state.copyWith(
      directionIsIncome: t.isIncome,
      amount: t.amount,
      memo: t.memo == '—' ? state.memo : t.memo,
      category: t.category,
      account: t.account,
      phase: AgentFlowPhase.confirm,
    );
  }
  if (presentation.kind == AgentPresentationKind.transferConfirm &&
      presentation.transfer != null) {
    return state.copyWith(
      isTransfer: true,
      transfer: presentation.transfer,
      phase: AgentFlowPhase.confirm,
    );
  }

  if (presentation.choicePanel != null) {
    return state.copyWith(phase: AgentFlowPhase.gathering);
  }

  return state;
}

class ParsedUserIntent {
  const ParsedUserIntent({this.amount, this.memo, this.isIncome});

  final String? amount;
  final String? memo;
  final bool? isIncome;
}

ParsedUserIntent parseUserTransactionIntent(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const ParsedUserIntent();

  final direction = inferTransactionDirection(trimmed);

  final spanishVerb = RegExp(
    r'^(compre|gaste|pague|recibi|gane|vendi|cobre|deposite)\s+(\d+(?:[.,]\d{1,2})?)\s*(.*)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (spanishVerb != null) {
    final rawAmount = spanishVerb.group(2)!.replaceAll(',', '.');
    final memo = spanishVerb.group(3)?.trim() ?? '';
    return ParsedUserIntent(
      amount: prettyAgentAmount(rawAmount),
      memo: _cleanMemo(memo),
      isIncome: direction,
    );
  }

  final amountFirst = RegExp(
    r'^[\$€£]?\s*([\d]+(?:[.,]\d{1,2})?)\s+(.*)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (amountFirst != null) {
    final rawAmount = amountFirst.group(1)!.replaceAll(',', '.');
    final memo = amountFirst.group(2)!.trim();
    return ParsedUserIntent(
      amount: prettyAgentAmount(rawAmount),
      memo: _cleanMemo(memo),
      isIncome: direction,
    );
  }

  final anyAmount = RegExp(r'([\d]+(?:[.,]\d{1,2})?)').firstMatch(trimmed);
  if (anyAmount != null) {
    final rawAmount = anyAmount.group(1)!.replaceAll(',', '.');
    final memo = trimmed.replaceFirst(anyAmount.group(0)!, '').trim();
    return ParsedUserIntent(
      amount: prettyAgentAmount(rawAmount),
      memo: _cleanMemo(memo),
      isIncome: direction,
    );
  }

  return ParsedUserIntent(memo: trimmed, isIncome: direction);
}

bool? inferTransactionDirection(String text) {
  final lower = text.toLowerCase();
  const incomePatterns = [
    'recib',
    'recibi',
    'recibí',
    'gane',
    'gané',
    'ganancia',
    'vend',
    'vendi',
    'vendí',
    'cobr',
    'cobre',
    'cobré',
    'deposit',
    'deposito',
    'depósito',
    'salary',
    'salario',
    'sueldo',
    'nomina',
    'nómina',
    'paycheck',
    'freelance',
    'income',
    'ingreso',
    'ingres',
    'paid me',
    'me pagaron',
    'cobro',
    'venta',
    'sold',
    'earned',
  ];
  const expensePatterns = [
    'compre',
    'compré',
    'gast',
    'gasté',
    'gaste',
    'pagu',
    'pagué',
    'pague',
    'spent',
    'bought',
    'expense',
    'gasto',
    'compra',
  ];

  for (final p in incomePatterns) {
    if (lower.contains(p)) return true;
  }
  for (final p in expensePatterns) {
    if (lower.contains(p)) return false;
  }
  return null;
}

String? _cleanMemo(String raw) {
  var memo = raw.trim();
  memo = memo.replaceFirst(
    RegExp(r'^(?:en el|en la|en|at|for)\s+', caseSensitive: false),
    '',
  );
  if (memo.isEmpty) return null;
  return memo;
}

String? parseAmountHint(String text) {
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    final match = RegExp(
      r'^(?:Amount|Monto):\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) return match.group(1)!.trim();
  }
  return null;
}

String prettyAgentAmount(String raw) {
  final cleaned = raw.trim().replaceAll(',', '');
  final value = double.tryParse(cleaned);
  if (value == null) return raw;
  if (value == value.roundToDouble()) {
    return '\$${value.toStringAsFixed(0)}';
  }
  return '\$${value.toStringAsFixed(2)}';
}

AgentFlowFieldKey? fieldKeyForCallback(String code) {
  if (code.startsWith('pc:')) return AgentFlowFieldKey.category;
  if (code.startsWith('pa:')) return AgentFlowFieldKey.account;
  if (code.startsWith('tf:') || code.startsWith('tt:')) {
    return AgentFlowFieldKey.account;
  }
  return null;
}

String? choiceLabelForCallback(AgentMessage message, String code) {
  for (final a in message.actions) {
    if (a.callbackCode == code) return a.label;
  }
  return null;
}
