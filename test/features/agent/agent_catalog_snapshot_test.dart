import 'package:flutter_test/flutter_test.dart';

import 'package:finko/core/data/models/agent_preferences.dart';
import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/features/agent/data/agent_catalog_snapshot.dart';
import 'package:finko/features/agent/data/agent_catalog_snapshot_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('round-trips catalog snapshot through SharedPreferences', () async {
    const uid = 'user-1';
    final snapshot = AgentCatalogSnapshot(
      categories: const [
        AgentCatalogCategory(
          id: 'food',
          name: 'Food',
          kind: CategoryKind.expense,
          sortOrder: 0,
        ),
      ],
      accounts: const [
        AgentCatalogAccount(
          id: 'cash',
          name: 'Cash',
          currency: 'MXN',
          sortOrder: 0,
        ),
      ],
      agentPreferences: const AgentPreferences(defaultAccountId: 'cash'),
    );

    await writeAgentCatalogSnapshot(uid, snapshot);
    final loaded = await readAgentCatalogSnapshot(uid);

    expect(loaded.categories, hasLength(1));
    expect(loaded.categories.first.name, 'Food');
    expect(loaded.accounts.first.id, 'cash');
    expect(loaded.agentPreferences?.defaultAccountId, 'cash');
  });

  test('clearAgentCatalogSnapshot removes stored data', () async {
    const uid = 'user-2';
    await writeAgentCatalogSnapshot(uid, AgentCatalogSnapshot.empty);
    await clearAgentCatalogSnapshot(uid);
    final loaded = await readAgentCatalogSnapshot(uid);
    expect(loaded.categories, isEmpty);
    expect(loaded.accounts, isEmpty);
  });
}
