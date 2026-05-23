import 'package:flutter_test/flutter_test.dart';

import 'package:finko/features/agent/domain/agent_message.dart';
import 'package:finko/features/agent/domain/agent_message_presentation.dart';

void main() {
  group('resolveAgentPresentation', () {
    test('parses transaction confirm card from EN template', () {
      const message = AgentMessage(
        id: '1',
        role: 'assistant',
        kind: 'text',
        text:
            'Please confirm transaction\n'
            'Type: OUT\n'
            'Amount: \$25.00\n'
            'Category: Food\n'
            'Account: Chase\n'
            'Note: Coffee',
        actions: [
          AgentActionChip(id: 'a0', label: '✓', callbackCode: 'cf'),
          AgentActionChip(id: 'a1', label: '✗', callbackCode: 'cx'),
        ],
      );

      final p = resolveAgentPresentation(message);
      expect(p.kind, AgentPresentationKind.transactionConfirm);
      expect(p.transaction!.amount, '\$25.00');
      expect(p.transaction!.category, 'Food');
      expect(p.transaction!.isIncome, isFalse);
    });

    test('parses category choice panel', () {
      const message = AgentMessage(
        id: '2',
        role: 'assistant',
        kind: 'text',
        text: 'Pick a category — tap a button:',
        actions: [
          AgentActionChip(id: 'a0', label: 'Food', callbackCode: 'pc:0'),
          AgentActionChip(id: 'a1', label: 'Travel', callbackCode: 'pc:1'),
          AgentActionChip(id: 'a2', label: '✗', callbackCode: 'cx'),
        ],
      );

      final p = resolveAgentPresentation(message);
      expect(p.kind, AgentPresentationKind.choicePanel);
      expect(p.choicePanel!.choices, hasLength(2));
      expect(p.cancelAction!.callbackCode, 'cx');
    });
  });
}
