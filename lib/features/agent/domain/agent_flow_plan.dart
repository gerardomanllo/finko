import '../../../core/data/models/agent_preferences.dart';
import '../../../core/data/models/finko_account.dart';
import '../../../core/data/models/finko_category.dart';
import '../../../core/data/models/finko_enums.dart';
import 'agent_message.dart';
import 'agent_message_presentation.dart';
import 'agent_transaction_flow.dart';

const _transferCategoryId = 'ledger-transfer';

enum AgentFlowStepKind { pickCategory, pickAccount, confirm }

class AgentFlowStep {
  const AgentFlowStep({required this.kind, this.panel});

  final AgentFlowStepKind kind;
  final AgentChoicePanelData? panel;
}

class AgentFlowPlan {
  const AgentFlowPlan({
    required this.steps,
    this.directionIsIncome,
    this.prefilledCategoryId,
    this.prefilledAccountId,
  });

  final List<AgentFlowStep> steps;
  final bool? directionIsIncome;
  final String? prefilledCategoryId;
  final String? prefilledAccountId;

  int get confirmStepIndex =>
      steps.indexWhere((s) => s.kind == AgentFlowStepKind.confirm);

  AgentFlowStep? stepAt(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }
}

AgentFlowPlan buildAgentFlowPlan({
  required ParsedUserIntent intent,
  required List<FinkoCategory> categories,
  required List<FinkoAccount> accounts,
  AgentPreferences? prefs,
}) {
  final isIncome = intent.isIncome;
  final kind = isIncome == true ? CategoryKind.income : CategoryKind.expense;

  final filteredCats =
      categories
          .where((c) => c.id != _transferCategoryId && c.kind == kind)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final sortedAccounts = [...accounts]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final defaultCatId = isIncome == true
      ? prefs?.defaultIncomeCategoryId?.trim()
      : isIncome == false
      ? prefs?.defaultExpenseCategoryId?.trim()
      : null;
  final defaultAccId = prefs?.defaultAccountId?.trim();

  final hasDefaultCat =
      defaultCatId != null &&
      defaultCatId.isNotEmpty &&
      filteredCats.any((c) => c.id == defaultCatId);
  final hasDefaultAcc =
      defaultAccId != null &&
      defaultAccId.isNotEmpty &&
      sortedAccounts.any((a) => a.id == defaultAccId);

  final steps = <AgentFlowStep>[];

  if (!hasDefaultCat && filteredCats.isNotEmpty) {
    steps.add(
      AgentFlowStep(
        kind: AgentFlowStepKind.pickCategory,
        panel: AgentChoicePanelData(
          style: AgentChoicePanelStyle.category,
          prompt: '',
          choices: [
            for (var i = 0; i < filteredCats.length; i++)
              AgentActionChip(
                id: 'pc$i',
                label: filteredCats[i].name,
                callbackCode: 'pc:$i',
              ),
          ],
        ),
      ),
    );
  }

  if (!hasDefaultAcc && sortedAccounts.isNotEmpty) {
    steps.add(
      AgentFlowStep(
        kind: AgentFlowStepKind.pickAccount,
        panel: AgentChoicePanelData(
          style: AgentChoicePanelStyle.account,
          prompt: '',
          choices: [
            for (var i = 0; i < sortedAccounts.length; i++)
              AgentActionChip(
                id: 'pa$i',
                label: _accountChoiceLabel(sortedAccounts[i]),
                callbackCode: 'pa:$i',
              ),
          ],
        ),
      ),
    );
  }

  steps.add(const AgentFlowStep(kind: AgentFlowStepKind.confirm));

  return AgentFlowPlan(
    steps: steps,
    directionIsIncome: isIncome,
    prefilledCategoryId: hasDefaultCat ? defaultCatId : null,
    prefilledAccountId: hasDefaultAcc ? defaultAccId : null,
  );
}

String _accountChoiceLabel(FinkoAccount account) {
  final name = account.name.length > 20
      ? account.name.substring(0, 20)
      : account.name;
  return '$name (${account.currency})';
}

/// Resolves which step to show based on filled fields and optional local override.
int resolveFlowStepIndex({
  required AgentFlowPlan plan,
  required AgentLiveTransactionState state,
  int? localOverride,
}) {
  if (state.phase == AgentFlowPhase.confirm ||
      state.phase == AgentFlowPhase.sealed) {
    return plan.confirmStepIndex;
  }

  if (localOverride != null) {
    return localOverride.clamp(0, plan.steps.length - 1);
  }

  for (var i = 0; i < plan.steps.length; i++) {
    final step = plan.steps[i];
    if (step.kind == AgentFlowStepKind.pickCategory && state.category == null) {
      return i;
    }
    if (step.kind == AgentFlowStepKind.pickAccount && state.account == null) {
      return i;
    }
  }
  return plan.confirmStepIndex;
}

AgentFlowFieldKey? fieldKeyForStep(AgentFlowStepKind kind) {
  return switch (kind) {
    AgentFlowStepKind.pickCategory => AgentFlowFieldKey.category,
    AgentFlowStepKind.pickAccount => AgentFlowFieldKey.account,
    AgentFlowStepKind.confirm => null,
  };
}

String? labelForPlanCallback(AgentFlowPlan plan, String code) {
  for (final step in plan.steps) {
    final panel = step.panel;
    if (panel == null) continue;
    for (final c in panel.choices) {
      if (c.callbackCode == code) return c.label;
    }
  }
  return null;
}

/// Income vs expense from a chosen category label (matches plan or server chip text).
bool? directionFromCategoryLabel(
  String? label,
  List<FinkoCategory> categories,
) {
  if (label == null || label.trim().isEmpty) return null;
  final needle = label.trim().toLowerCase();
  for (final c in categories) {
    final name = c.name.trim().toLowerCase();
    if (name == needle || name.startsWith(needle) || needle.startsWith(name)) {
      return c.kind == CategoryKind.income;
    }
  }
  return null;
}
