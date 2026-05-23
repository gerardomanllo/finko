import 'package:flutter_test/flutter_test.dart';

import 'package:finko/features/agent/domain/agent_message.dart';
import 'package:finko/features/agent/domain/agent_transaction_flow.dart';

void main() {
  group('segmentAgentThread', () {
    test('groups pick steps into one flow segment', () {
      final messages = [
        const AgentMessage(
          id: 'u1',
          role: 'user',
          kind: 'text',
          text: '25 coffee',
        ),
        const AgentMessage(
          id: 'a1',
          role: 'assistant',
          kind: 'text',
          text: 'Amount: \$25.00\n\nPick a category — tap a button:',
          actions: [
            AgentActionChip(id: '0', label: 'Food', callbackCode: 'pc:0'),
            AgentActionChip(id: '1', label: '✗', callbackCode: 'cx'),
          ],
        ),
        const AgentMessage(
          id: 'a2',
          role: 'assistant',
          kind: 'text',
          text: 'Amount: \$25.00\n\nPick an account — tap a button:',
          actions: [
            AgentActionChip(
              id: '0',
              label: 'Chase (USD)',
              callbackCode: 'pa:0',
            ),
            AgentActionChip(id: '1', label: '✗', callbackCode: 'cx'),
          ],
        ),
      ];

      final segments = segmentAgentThread(messages);
      expect(segments, hasLength(2));
      expect(segments[0], isA<AgentThreadUserSegment>());
      expect(segments[1], isA<AgentThreadFlowSegment>());
      final flow = (segments[1] as AgentThreadFlowSegment).flow;
      expect(flow.assistantMessages, hasLength(2));
      expect(flow.state.amount, '\$25.00');
      expect(flow.state.memo, 'coffee');
    });

    test('seals flow on posted message', () {
      final messages = [
        const AgentMessage(
          id: 'u1',
          role: 'user',
          kind: 'text',
          text: '25 coffee',
        ),
        const AgentMessage(
          id: 'a1',
          role: 'assistant',
          kind: 'text',
          text:
              'Please confirm transaction\nType: OUT\nAmount: \$25.00\nCategory: Food\nAccount: Chase\nNote: coffee',
          actions: [
            AgentActionChip(id: '0', label: '✓', callbackCode: 'cf'),
            AgentActionChip(id: '1', label: '✗', callbackCode: 'cx'),
          ],
        ),
        const AgentMessage(
          id: 'a2',
          role: 'assistant',
          kind: 'text',
          text: 'Expense recorded: coffee — \$25.00',
        ),
      ];

      final flow =
          (segmentAgentThread(messages)[1] as AgentThreadFlowSegment).flow;
      expect(flow.state.phase, AgentFlowPhase.sealed);
      expect(flow.activeMessage, isNull);
    });
  });

  group('parseUserTransactionIntent', () {
    test('extracts amount and memo', () {
      final intent = parseUserTransactionIntent('25 coffee');
      expect(intent.amount, '\$25');
      expect(intent.memo, 'coffee');
    });

    test('parses Spanish expense phrase', () {
      final intent = parseUserTransactionIntent('compre 500 en el super');
      expect(intent.amount, '\$500');
      expect(intent.memo, 'super');
      expect(intent.isIncome, isFalse);
    });

    test('detects income from Spanish phrase', () {
      final intent = parseUserTransactionIntent('recibi 500 de freelance');
      expect(intent.amount, '\$500');
      expect(intent.isIncome, isTrue);
    });
  });
}
