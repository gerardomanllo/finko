import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../user_profile/user_locale_repository.dart';
import 'locale_support.dart';

final localeNotifierProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final repo = ref.watch(userLocaleRepositoryProvider);

    final sub = repo.remoteLocaleUpdates.listen(
      (remote) async {
        if (remote == null) return;
        final current = state.asData?.value;
        if (current == remote) return;
        await repo.cacheLocaleLocally(remote);
        state = AsyncData(remote);
      },
      onError: (_, stackTrace) {
        // Auth transitions can briefly invalidate user-scoped streams.
      },
    );
    ref.onDispose(sub.cancel);

    return repo.loadEffectiveLocale();
  }

  /// Persists locally and to `users/{uid}.locale` when authenticated.
  Future<void> setLocale(Locale locale) async {
    final normalized = normalizeAppLocale(locale);
    final repo = ref.read(userLocaleRepositoryProvider);
    await repo.persistLocale(normalized);
    state = AsyncData(normalized);
  }
}
