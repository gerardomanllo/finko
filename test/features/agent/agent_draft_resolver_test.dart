import 'package:flutter_test/flutter_test.dart';

import 'package:finko/core/data/models/agent_preferences.dart';
import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/features/agent/data/agent_catalog_snapshot.dart';
import 'package:finko/features/agent/domain/agent_draft_resolver.dart';
import 'package:finko/features/agent/domain/agent_flow_plan.dart';
import 'package:finko/features/agent/domain/agent_transaction_flow.dart';

AgentCatalogSnapshot _catalog() {
  return const AgentCatalogSnapshot(
    categories: [
      AgentCatalogCategory(
        id: 'food',
        name: 'Food',
        kind: CategoryKind.expense,
        sortOrder: 0,
      ),
      AgentCatalogCategory(
        id: 'salary',
        name: 'Salary',
        kind: CategoryKind.income,
        sortOrder: 1,
      ),
    ],
    accounts: [
      AgentCatalogAccount(
        id: 'chase',
        name: 'Chase',
        currency: 'USD',
        sortOrder: 0,
      ),
      AgentCatalogAccount(
        id: 'cash',
        name: 'Cash',
        currency: 'MXN',
        sortOrder: 1,
      ),
    ],
    agentPreferences: AgentPreferences(
      defaultAccountId: 'cash',
      defaultExpenseCategoryId: 'food',
      defaultIncomeCategoryId: 'salary',
    ),
  );
}

void main() {
  group('resolveAgentDraft', () {
    test('parses explicit amount and memo', () {
      final draft = resolveAgentDraft(text: '50 coffee', catalog: _catalog());
      expect(draft.amount, '\$50');
      expect(draft.memo, 'coffee');
      expect(
        draft.sourceFor(AgentFlowFieldKey.amount),
        AgentFieldSource.explicit,
      );
    });

    test('defaults direction to expense when not inferred', () {
      final draft = resolveAgentDraft(text: '50 coffee', catalog: _catalog());
      expect(draft.directionIsIncome, false);
      expect(
        draft.sourceFor(AgentFlowFieldKey.direction),
        AgentFieldSource.defaulted,
      );
    });

    test('defaults category and account from preferences', () {
      final draft = resolveAgentDraft(text: '50 coffee', catalog: _catalog());
      expect(draft.categoryId, 'food');
      expect(draft.accountId, 'cash');
      expect(
        draft.sourceFor(AgentFlowFieldKey.category),
        AgentFieldSource.defaulted,
      );
      expect(
        draft.sourceFor(AgentFlowFieldKey.account),
        AgentFieldSource.defaulted,
      );
    });

    test('matches category name in text implicitly', () {
      final draft = resolveAgentDraft(
        text: '50 Food delivery',
        catalog: _catalog(),
      );
      expect(draft.categoryId, 'food');
      expect(
        draft.sourceFor(AgentFlowFieldKey.category),
        AgentFieldSource.implicit,
      );
    });

    test('matches account name in text implicitly', () {
      final draft = resolveAgentDraft(
        text: '100 lunch on Chase',
        catalog: _catalog(),
      );
      expect(draft.accountId, 'chase');
      expect(
        draft.sourceFor(AgentFlowFieldKey.account),
        AgentFieldSource.implicit,
      );
    });

    test('infers income direction from keywords', () {
      final draft = resolveAgentDraft(
        text: 'recibi 500 salary',
        catalog: _catalog(),
      );
      expect(draft.directionIsIncome, true);
      expect(
        draft.sourceFor(AgentFlowFieldKey.direction),
        AgentFieldSource.explicit,
      );
      expect(draft.categoryId, 'salary');
    });
  });

  group('buildAgentFlowPlan', () {
    test('confirm-only when draft resolves category and account', () {
      final catalog = _catalog();
      final draft = resolveAgentDraft(text: '25 coffee', catalog: catalog);
      final plan = buildAgentFlowPlan(
        draft: draft,
        categories: catalog.finkoCategories,
        accounts: catalog.finkoAccounts,
      );
      expect(plan.steps, hasLength(1));
      expect(plan.steps.single.kind, AgentFlowStepKind.confirm);
    });

    test('includes pickers when defaults missing', () {
      final catalog = const AgentCatalogSnapshot(
        categories: [
          AgentCatalogCategory(
            id: 'food',
            name: 'Food',
            kind: CategoryKind.expense,
            sortOrder: 0,
          ),
        ],
        accounts: [
          AgentCatalogAccount(
            id: 'cash',
            name: 'Cash',
            currency: 'MXN',
            sortOrder: 0,
          ),
        ],
      );
      final draft = resolveAgentDraft(text: '25 coffee', catalog: catalog);
      final plan = buildAgentFlowPlan(
        draft: draft,
        categories: catalog.finkoCategories,
        accounts: catalog.finkoAccounts,
      );
      expect(plan.steps.length, greaterThan(1));
      expect(
        plan.steps.any((s) => s.kind == AgentFlowStepKind.pickCategory),
        isTrue,
      );
      expect(
        plan.steps.any((s) => s.kind == AgentFlowStepKind.pickAccount),
        isTrue,
      );
    });
  });
}
