import '../../../core/data/models/agent_preferences.dart';
import '../../../core/data/models/finko_enums.dart';
import '../data/agent_catalog_snapshot.dart';
import 'agent_transaction_flow.dart';

const _transferCategoryId = 'ledger-transfer';

class ResolvedAgentDraft {
  const ResolvedAgentDraft({
    this.amount,
    this.memo,
    this.directionIsIncome,
    this.categoryId,
    this.accountId,
    this.sources = const {},
  });

  final String? amount;
  final String? memo;
  final bool? directionIsIncome;
  final String? categoryId;
  final String? accountId;
  final Map<AgentFlowFieldKey, AgentFieldSource> sources;

  bool? get isIncome => directionIsIncome;

  bool get hasResolvableIntent =>
      amount != null || (memo != null && memo!.trim().isNotEmpty);

  bool get categoryResolved =>
      categoryId != null && categoryId!.trim().isNotEmpty;

  bool get accountResolved => accountId != null && accountId!.trim().isNotEmpty;

  AgentFieldSource sourceFor(AgentFlowFieldKey key) =>
      sources[key] ?? AgentFieldSource.unset;

  ResolvedAgentDraft copyWith({
    String? amount,
    String? memo,
    bool? directionIsIncome,
    String? categoryId,
    String? accountId,
    Map<AgentFlowFieldKey, AgentFieldSource>? sources,
  }) {
    return ResolvedAgentDraft(
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      directionIsIncome: directionIsIncome ?? this.directionIsIncome,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      sources: sources ?? this.sources,
    );
  }
}

/// Resolves amount, direction, memo, category, and account from user text and
/// the local catalog (explicit → implicit → preference default).
ResolvedAgentDraft resolveAgentDraft({
  required String text,
  required AgentCatalogSnapshot catalog,
  Map<AgentFlowFieldKey, String>? localOverrides,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const ResolvedAgentDraft();

  final intent = parseUserTransactionIntent(trimmed);
  final sources = <AgentFlowFieldKey, AgentFieldSource>{};

  String? amount = intent.amount;
  String? memo = intent.memo;
  bool? direction = intent.isIncome;

  if (amount != null) {
    sources[AgentFlowFieldKey.amount] = AgentFieldSource.explicit;
  }
  if (memo != null && memo.isNotEmpty) {
    sources[AgentFlowFieldKey.memo] = AgentFieldSource.explicit;
  }
  if (direction != null) {
    sources[AgentFlowFieldKey.direction] = AgentFieldSource.explicit;
  }

  final prefs = catalog.agentPreferences;
  final categories = catalog.categories
      .where((c) => c.id != _transferCategoryId)
      .toList();
  final accounts = catalog.accounts;

  String? categoryId = _matchCategoryInText(trimmed, categories, direction);
  if (categoryId != null) {
    sources[AgentFlowFieldKey.category] = AgentFieldSource.implicit;
    final cat = categories.firstWhere((c) => c.id == categoryId);
    if (direction == null) {
      direction = cat.kind == CategoryKind.income;
      sources[AgentFlowFieldKey.direction] = AgentFieldSource.implicit;
    }
  }

  String? accountId = _matchAccountInText(trimmed, accounts);
  if (accountId != null) {
    sources[AgentFlowFieldKey.account] = AgentFieldSource.implicit;
  }

  if (direction == null) {
    direction = false;
    sources[AgentFlowFieldKey.direction] = AgentFieldSource.defaulted;
  }

  if (categoryId == null) {
    categoryId = _defaultCategoryId(prefs, direction, categories);
    if (categoryId != null) {
      sources[AgentFlowFieldKey.category] = AgentFieldSource.defaulted;
    }
  }

  if (accountId == null) {
    accountId = _defaultAccountId(prefs, accounts);
    if (accountId != null) {
      sources[AgentFlowFieldKey.account] = AgentFieldSource.defaulted;
    }
  }

  var draft = ResolvedAgentDraft(
    amount: amount,
    memo: memo,
    directionIsIncome: direction,
    categoryId: categoryId,
    accountId: accountId,
    sources: sources,
  );

  if (localOverrides != null && localOverrides.isNotEmpty) {
    draft = _applyLocalOverrides(draft, localOverrides, categories, accounts);
  }

  return draft;
}

ResolvedAgentDraft _applyLocalOverrides(
  ResolvedAgentDraft draft,
  Map<AgentFlowFieldKey, String> overrides,
  List<AgentCatalogCategory> categories,
  List<AgentCatalogAccount> accounts,
) {
  var next = draft;
  final sources = Map<AgentFlowFieldKey, AgentFieldSource>.from(draft.sources);

  for (final entry in overrides.entries) {
    if (entry.value == agentLocalFieldCleared) {
      sources[entry.key] = AgentFieldSource.unset;
      next = switch (entry.key) {
        AgentFlowFieldKey.amount => next.copyWith(amount: null),
        AgentFlowFieldKey.memo => next.copyWith(memo: null),
        AgentFlowFieldKey.direction => next.copyWith(directionIsIncome: null),
        AgentFlowFieldKey.category => next.copyWith(categoryId: null),
        AgentFlowFieldKey.account => next.copyWith(accountId: null),
      };
      continue;
    }

    sources[entry.key] = AgentFieldSource.explicit;
    next = switch (entry.key) {
      AgentFlowFieldKey.amount => next.copyWith(amount: entry.value),
      AgentFlowFieldKey.memo => next.copyWith(memo: entry.value),
      AgentFlowFieldKey.direction => next.copyWith(
        directionIsIncome: entry.value.toUpperCase() == 'IN',
      ),
      AgentFlowFieldKey.category => next.copyWith(
        categoryId: _categoryIdForLabel(entry.value, categories) ?? entry.value,
      ),
      AgentFlowFieldKey.account => next.copyWith(
        accountId: _accountIdForLabel(entry.value, accounts) ?? entry.value,
      ),
    };
  }

  return next.copyWith(sources: sources);
}

String? _matchCategoryInText(
  String text,
  List<AgentCatalogCategory> categories,
  bool? directionIsIncome,
) {
  final kind = directionIsIncome == true
      ? CategoryKind.income
      : directionIsIncome == false
      ? CategoryKind.expense
      : null;

  final candidates = categories.where((c) {
    if (kind != null && c.kind != kind) return false;
    return true;
  }).toList();

  return _bestNameMatch(text, candidates.map((c) => (c.id, c.name)).toList());
}

String? _matchAccountInText(String text, List<AgentCatalogAccount> accounts) {
  return _bestNameMatch(text, accounts.map((a) => (a.id, a.name)).toList());
}

String? _bestNameMatch(String text, List<(String id, String name)> rows) {
  final lower = text.toLowerCase();
  String? bestId;
  var bestLen = 0;

  for (final (id, name) in rows) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) continue;
    if (!_textContainsName(lower, needle)) continue;
    if (needle.length > bestLen) {
      bestLen = needle.length;
      bestId = id;
    }
  }
  return bestId;
}

bool _textContainsName(String lowerText, String lowerName) {
  if (lowerName.contains(' ')) {
    return lowerText.contains(lowerName);
  }
  final pattern = RegExp(
    '(?<![\\wáéíóúñ])${RegExp.escape(lowerName)}(?![\\wáéíóúñ])',
  );
  return pattern.hasMatch(lowerText) || lowerText.contains(lowerName);
}

String? _defaultCategoryId(
  AgentPreferences? prefs,
  bool directionIsIncome,
  List<AgentCatalogCategory> categories,
) {
  final raw = directionIsIncome
      ? prefs?.defaultIncomeCategoryId?.trim()
      : prefs?.defaultExpenseCategoryId?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (categories.any((c) => c.id == raw)) return raw;
  return null;
}

String? _defaultAccountId(
  AgentPreferences? prefs,
  List<AgentCatalogAccount> accounts,
) {
  final raw = prefs?.defaultAccountId?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (accounts.any((a) => a.id == raw)) return raw;
  return null;
}

String? _categoryIdForLabel(
  String label,
  List<AgentCatalogCategory> categories,
) {
  final needle = label.trim().toLowerCase();
  for (final c in categories) {
    if (c.name.trim().toLowerCase() == needle) return c.id;
  }
  return null;
}

String? _accountIdForLabel(String label, List<AgentCatalogAccount> accounts) {
  final needle = label.trim().toLowerCase();
  for (final a in accounts) {
    final name = a.name.trim().toLowerCase();
    final withCurrency = '$name (${a.currency.toLowerCase()})';
    if (needle == name || needle == withCurrency) return a.id;
  }
  return null;
}

/// Builds display labels and field sources for the live transaction card.
AgentLiveTransactionState draftToLiveState(
  ResolvedAgentDraft draft,
  AgentCatalogSnapshot catalog,
) {
  var state = AgentLiveTransactionState(
    directionIsIncome: draft.directionIsIncome,
    amount: draft.amount,
    memo: draft.memo,
    phase: AgentFlowPhase.gathering,
    fieldSources: draft.sources,
  );

  if (draft.categoryId != null) {
    for (final c in catalog.categories) {
      if (c.id == draft.categoryId) {
        state = state.copyWith(
          category: c.name,
          directionIsIncome:
              draft.directionIsIncome ?? c.kind == CategoryKind.income,
        );
        break;
      }
    }
  }

  if (draft.accountId != null) {
    for (final a in catalog.accounts) {
      if (a.id == draft.accountId) {
        state = state.copyWith(account: _accountDisplayLabel(a));
        break;
      }
    }
  }

  if (draft.categoryResolved && draft.accountResolved && draft.amount != null) {
    state = state.copyWith(phase: AgentFlowPhase.confirm);
  }

  return state;
}

String _accountDisplayLabel(AgentCatalogAccount account) {
  final name = account.name.length > 20
      ? account.name.substring(0, 20)
      : account.name;
  return '$name (${account.currency})';
}

String accountDisplayLabelForId(
  String accountId,
  AgentCatalogSnapshot catalog,
) {
  for (final a in catalog.accounts) {
    if (a.id == accountId) return _accountDisplayLabel(a);
  }
  return accountId;
}

String? categoryNameForId(String categoryId, AgentCatalogSnapshot catalog) {
  for (final c in catalog.categories) {
    if (c.id == categoryId) return c.name;
  }
  return null;
}
