import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import 'agent_catalog_snapshot.dart';
import 'agent_catalog_snapshot_store.dart';

/// In-memory catalog for the agent: prefers live Firestore streams, falls back
/// to the last device snapshot (SharedPreferences).
final agentCatalogProvider = Provider<AgentCatalogSnapshot>((ref) {
  final uid = ref.watch(authUidProvider);
  if (uid == null) return AgentCatalogSnapshot.empty;

  ref.watch(agentCatalogSnapshotRevisionProvider);

  final liveCats = ref.watch(categoriesStreamProvider).valueOrNull;
  final liveAccs = ref.watch(accountsStreamProvider).valueOrNull;
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;

  if (liveCats != null && liveAccs != null) {
    return AgentCatalogSnapshot.fromLive(
      categories: liveCats,
      accounts: liveAccs,
      agentPreferences: profile?.agentPreferences,
    );
  }

  final cached = ref.watch(cachedAgentCatalogProvider(uid)).valueOrNull;
  if (cached != null &&
      (cached.categories.isNotEmpty || cached.accounts.isNotEmpty)) {
    return cached;
  }

  if (liveCats != null || liveAccs != null) {
    return AgentCatalogSnapshot.fromLive(
      categories: liveCats ?? const [],
      accounts: liveAccs ?? const [],
      agentPreferences: profile?.agentPreferences,
    );
  }

  return cached ?? AgentCatalogSnapshot.empty;
});

/// Async read of the on-disk snapshot (invalidated when sync listener writes).
final cachedAgentCatalogProvider =
    FutureProvider.family<AgentCatalogSnapshot, String>((ref, uid) async {
      ref.watch(agentCatalogSnapshotRevisionProvider);
      return readAgentCatalogSnapshot(uid);
    });

/// Bump to invalidate catalog providers after persisting a new snapshot.
final agentCatalogSnapshotRevisionProvider = StateProvider<int>((ref) => 0);

void bumpAgentCatalogRevision(WidgetRef ref) {
  ref.read(agentCatalogSnapshotRevisionProvider.notifier).state++;
}

void bumpAgentCatalogRevisionFromRef(Ref ref) {
  ref.read(agentCatalogSnapshotRevisionProvider.notifier).state++;
}
