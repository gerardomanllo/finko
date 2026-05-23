import 'agent_message.dart';

enum AgentPresentationKind {
  userText,
  assistantText,
  transactionConfirm,
  transferConfirm,
  choicePanel,
  fallback,
}

class AgentTransactionPreview {
  const AgentTransactionPreview({
    required this.isIncome,
    required this.amount,
    required this.category,
    required this.account,
    required this.memo,
  });

  final bool isIncome;
  final String amount;
  final String category;
  final String account;
  final String memo;
}

class AgentTransferPreview {
  const AgentTransferPreview({
    required this.fromAccount,
    required this.toAccount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amountOut,
    required this.amountIn,
    required this.memo,
  });

  final String fromAccount;
  final String toAccount;
  final String fromCurrency;
  final String toCurrency;
  final String amountOut;
  final String amountIn;
  final String memo;
}

enum AgentChoicePanelStyle { category, account, transfer, recurring, generic }

class AgentChoicePanelData {
  const AgentChoicePanelData({
    required this.style,
    required this.prompt,
    required this.choices,
  });

  final AgentChoicePanelStyle style;
  final String prompt;
  final List<AgentActionChip> choices;
}

class AgentMessagePresentation {
  const AgentMessagePresentation({
    required this.kind,
    this.text,
    this.transaction,
    this.transfer,
    this.choicePanel,
    this.confirmActions = const [],
    this.cancelAction,
  });

  final AgentPresentationKind kind;
  final String? text;
  final AgentTransactionPreview? transaction;
  final AgentTransferPreview? transfer;
  final AgentChoicePanelData? choicePanel;
  final List<AgentActionChip> confirmActions;
  final AgentActionChip? cancelAction;
}

AgentMessagePresentation resolveAgentPresentation(AgentMessage message) {
  if (message.isUser) {
    return AgentMessagePresentation(
      kind: AgentPresentationKind.userText,
      text: message.text?.trim(),
    );
  }

  final codes = message.actions.map((a) => a.callbackCode).toList();
  final text = message.text?.trim() ?? '';

  if (_hasConfirmActions(codes)) {
    final transfer = _parseTransferPreview(text);
    if (transfer != null) {
      return AgentMessagePresentation(
        kind: AgentPresentationKind.transferConfirm,
        transfer: transfer,
        confirmActions: _confirmChip(message.actions),
        cancelAction: _cancelChip(message.actions),
      );
    }
    final transaction = _parseTransactionPreview(text);
    if (transaction != null) {
      return AgentMessagePresentation(
        kind: AgentPresentationKind.transactionConfirm,
        transaction: transaction,
        confirmActions: _confirmChip(message.actions),
        cancelAction: _cancelChip(message.actions),
      );
    }
  }

  final choicePanel = _parseChoicePanel(message.actions, text);
  if (choicePanel != null) {
    return AgentMessagePresentation(
      kind: AgentPresentationKind.choicePanel,
      choicePanel: choicePanel,
      cancelAction: _cancelChip(message.actions),
    );
  }

  if (text.isNotEmpty || message.actions.isNotEmpty) {
    return AgentMessagePresentation(
      kind: text.isEmpty
          ? AgentPresentationKind.fallback
          : AgentPresentationKind.assistantText,
      text: text.isEmpty ? null : text,
      confirmActions: message.actions
          .where((a) => a.callbackCode == 'cf')
          .toList(),
      cancelAction: _cancelChip(message.actions),
    );
  }

  return const AgentMessagePresentation(kind: AgentPresentationKind.fallback);
}

bool _hasConfirmActions(List<String> codes) =>
    codes.contains('cf') && codes.contains('cx');

List<AgentActionChip> _confirmChip(List<AgentActionChip> actions) =>
    actions.where((a) => a.callbackCode == 'cf').toList();

AgentActionChip? _cancelChip(List<AgentActionChip> actions) {
  for (final a in actions) {
    if (a.callbackCode == 'cx' || a.callbackCode == 'rn') return a;
  }
  return null;
}

AgentChoicePanelData? _parseChoicePanel(
  List<AgentActionChip> actions,
  String text,
) {
  if (actions.isEmpty) return null;

  final choices = actions.where((a) {
    final code = a.callbackCode;
    return code != 'cx' && code != 'rn';
  }).toList();
  if (choices.isEmpty) return null;

  final codes = actions.map((a) => a.callbackCode).toList();
  AgentChoicePanelStyle style = AgentChoicePanelStyle.generic;
  if (codes.any((c) => c.startsWith('pc:'))) {
    style = AgentChoicePanelStyle.category;
  } else if (codes.any((c) => c.startsWith('pa:'))) {
    style = AgentChoicePanelStyle.account;
  } else if (codes.any((c) => c.startsWith('tf:') || c.startsWith('tt:'))) {
    style = AgentChoicePanelStyle.transfer;
  } else if (codes.any((c) => const {'rm', 'rt', 'rb', 'rw'}.contains(c))) {
    style = AgentChoicePanelStyle.recurring;
  } else if (choices.length <= 2 && _hasConfirmActions(codes)) {
    return null;
  }

  if (style == AgentChoicePanelStyle.generic && choices.length <= 2) {
    return null;
  }

  return AgentChoicePanelData(
    style: style,
    prompt: _extractPrompt(text),
    choices: choices,
  );
}

String _extractPrompt(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return text;
  return lines.first;
}

String? _field(Map<String, String> fields, List<String> keys) {
  for (final key in keys) {
    final value = fields[key.toLowerCase()];
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

Map<String, String> _parseKeyValueLines(String text) {
  final out = <String, String>{};
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    final colon = line.indexOf(':');
    if (colon <= 0) continue;
    final key = line.substring(0, colon).trim().toLowerCase();
    final value = line.substring(colon + 1).trim();
    out[key] = value;
  }
  return out;
}

AgentTransactionPreview? _parseTransactionPreview(String text) {
  if (!text.toLowerCase().contains('confirm') &&
      !text.toLowerCase().contains('confirma')) {
    return null;
  }
  final fields = _parseKeyValueLines(text);
  final direction = _field(fields, ['type', 'tipo'])?.toUpperCase();
  final amount = _field(fields, ['amount', 'monto']);
  final category = _field(fields, ['category', 'categoría', 'categoria']);
  final account = _field(fields, ['account', 'cuenta']);
  final memo = _field(fields, ['note', 'nota']);
  if (amount == null || category == null || account == null) return null;
  return AgentTransactionPreview(
    isIncome: direction == 'IN',
    amount: amount,
    category: category,
    account: account,
    memo: memo ?? '—',
  );
}

AgentTransferPreview? _parseTransferPreview(String text) {
  final lower = text.toLowerCase();
  if (!lower.contains('transfer') && !lower.contains('transferencia')) {
    return null;
  }
  final fields = _parseKeyValueLines(text);
  final fromRaw = _field(fields, ['from', 'desde']);
  final toRaw = _field(fields, ['to', 'hacia']);
  final amountOut = _field(fields, ['out', 'salida']);
  final amountIn = _field(fields, ['in', 'entrada']);
  final memo = _field(fields, ['note', 'nota']);
  if (fromRaw == null || toRaw == null || amountOut == null) return null;

  final from = _splitAccountCurrency(fromRaw);
  final to = _splitAccountCurrency(toRaw);

  return AgentTransferPreview(
    fromAccount: from.$1,
    toAccount: to.$1,
    fromCurrency: from.$2,
    toCurrency: to.$2,
    amountOut: amountOut,
    amountIn: amountIn ?? amountOut,
    memo: memo ?? '—',
  );
}

(String account, String currency) _splitAccountCurrency(String raw) {
  final match = RegExp(r'^(.*)\(([^)]+)\)\s*$').firstMatch(raw.trim());
  if (match == null) return (raw.trim(), '');
  return (match.group(1)!.trim(), match.group(2)!.trim());
}
