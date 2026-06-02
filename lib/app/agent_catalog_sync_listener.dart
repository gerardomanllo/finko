import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/firebase_auth_providers.dart';
import '../core/data/models/finko_account.dart';
import '../core/data/models/finko_category.dart';
import '../core/data/models/user_profile.dart';
import '../core/data/providers/finko_stream_providers.dart';
import '../features/agent/data/agent_catalog_provider.dart';
import '../features/agent/data/agent_catalog_snapshot.dart';
import '../features/agent/data/agent_catalog_snapshot_store.dart';

/// Persists categories, accounts, and agent preferences to SharedPreferences
/// whenever Firestore streams emit, so the agent has instant picker data offline.
class AgentCatalogSyncListener extends ConsumerWidget {
  const AgentCatalogSyncListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<List<FinkoCategory>>>(categoriesStreamProvider, (
      _,
      next,
    ) {
      _maybePersist(ref, categories: next.valueOrNull);
    });
    ref.listen<AsyncValue<List<FinkoAccount>>>(accountsStreamProvider, (
      _,
      next,
    ) {
      _maybePersist(ref, accounts: next.valueOrNull);
    });
    ref.listen<AsyncValue<UserProfile?>>(userProfileStreamProvider, (_, next) {
      _maybePersist(ref, profile: next.valueOrNull);
    });
    return child;
  }

  void _maybePersist(
    WidgetRef ref, {
    List<FinkoCategory>? categories,
    List<FinkoAccount>? accounts,
    UserProfile? profile,
  }) {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;

    final cats = categories ?? ref.read(categoriesStreamProvider).valueOrNull;
    final accs = accounts ?? ref.read(accountsStreamProvider).valueOrNull;
    if (cats == null || accs == null) return;

    final prefs =
        profile?.agentPreferences ??
        ref.read(userProfileStreamProvider).valueOrNull?.agentPreferences;

    writeAgentCatalogSnapshot(
      uid,
      AgentCatalogSnapshot.fromLive(
        categories: cats,
        accounts: accs,
        agentPreferences: prefs,
      ),
    ).then((_) => bumpAgentCatalogRevision(ref));
  }
}
