import '../../../core/data/models/agent_preferences.dart';
import '../../../core/data/models/finko_account.dart';
import '../../../core/data/models/finko_category.dart';
import '../../../core/data/models/finko_enums.dart';

/// Slim category row persisted for instant agent resolution (no icon/budget fields).
class AgentCatalogCategory {
  const AgentCatalogCategory({
    required this.id,
    required this.name,
    required this.kind,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final int sortOrder;

  factory AgentCatalogCategory.fromFinko(FinkoCategory c) {
    return AgentCatalogCategory(
      id: c.id,
      name: c.name,
      kind: c.kind,
      sortOrder: c.sortOrder,
    );
  }

  FinkoCategory toFinko() {
    return FinkoCategory(
      id: id,
      name: name,
      kind: kind,
      iconKey: 'category',
      sortOrder: sortOrder,
    );
  }

  factory AgentCatalogCategory.fromJson(Map<String, dynamic> json) {
    return AgentCatalogCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      kind:
          CategoryKind.tryParse(json['kind'] as String?) ??
          CategoryKind.expense,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.wireName,
    'sortOrder': sortOrder,
  };
}

/// Slim account row persisted for instant agent resolution (no balances/timestamps).
class AgentCatalogAccount {
  const AgentCatalogAccount({
    required this.id,
    required this.name,
    required this.currency,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String currency;
  final int sortOrder;

  factory AgentCatalogAccount.fromFinko(FinkoAccount a) {
    return AgentCatalogAccount(
      id: a.id,
      name: a.name,
      currency: a.currency,
      sortOrder: a.sortOrder,
    );
  }

  FinkoAccount toFinko({DateTime? now}) {
    final ts = now ?? DateTime.utc(2020);
    return FinkoAccount(
      id: id,
      name: name,
      type: FinkoAccountType.checking,
      currency: currency,
      balanceMinor: 0,
      includeInNetCash: true,
      sortOrder: sortOrder,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  factory AgentCatalogAccount.fromJson(Map<String, dynamic> json) {
    return AgentCatalogAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String? ?? 'MXN',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'currency': currency,
    'sortOrder': sortOrder,
  };
}

/// Device-local snapshot of agent pickers + preference defaults.
class AgentCatalogSnapshot {
  const AgentCatalogSnapshot({
    this.categories = const [],
    this.accounts = const [],
    this.agentPreferences,
    this.updatedAt,
  });

  final List<AgentCatalogCategory> categories;
  final List<AgentCatalogAccount> accounts;
  final AgentPreferences? agentPreferences;
  final DateTime? updatedAt;

  static const empty = AgentCatalogSnapshot();

  List<FinkoCategory> get finkoCategories =>
      categories.map((c) => c.toFinko()).toList();

  List<FinkoAccount> get finkoAccounts =>
      accounts.map((a) => a.toFinko()).toList();

  factory AgentCatalogSnapshot.fromLive({
    required List<FinkoCategory> categories,
    required List<FinkoAccount> accounts,
    AgentPreferences? agentPreferences,
  }) {
    return AgentCatalogSnapshot(
      categories: categories.map(AgentCatalogCategory.fromFinko).toList(),
      accounts: accounts.map(AgentCatalogAccount.fromFinko).toList(),
      agentPreferences: agentPreferences,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  factory AgentCatalogSnapshot.fromJson(Map<String, dynamic> json) {
    final cats = json['categories'];
    final accs = json['accounts'];
    return AgentCatalogSnapshot(
      categories: cats is List
          ? cats
                .whereType<Map>()
                .map(
                  (m) => AgentCatalogCategory.fromJson(
                    Map<String, dynamic>.from(m),
                  ),
                )
                .toList()
          : const [],
      accounts: accs is List
          ? accs
                .whereType<Map>()
                .map(
                  (m) => AgentCatalogAccount.fromJson(
                    Map<String, dynamic>.from(m),
                  ),
                )
                .toList()
          : const [],
      agentPreferences: agentPreferencesFromJson(json['agentPreferences']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'categories': categories.map((c) => c.toJson()).toList(),
    'accounts': accounts.map((a) => a.toJson()).toList(),
    if (agentPreferences != null)
      'agentPreferences': agentPreferences!.toJson(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}
