import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/firebase_auth_providers.dart';
import '../core/data/models/user_profile.dart';
import '../core/data/providers/finko_stream_providers.dart';
import '../core/theme/theme_mode_provider.dart';

/// Applies `users/{uid}.themePreference` to [themeModeProvider] whenever the
/// profile stream updates (and resets to system when signed out).
class ProfileThemeSyncListener extends ConsumerWidget {
  const ProfileThemeSyncListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<UserProfile?>>(userProfileStreamProvider, (
      previous,
      next,
    ) {
      final uid = ref.read(authUidProvider);
      if (uid == null) {
        ref.read(themeModeProvider.notifier).setFromPreference('system');
        return;
      }
      final profile = next.valueOrNull;
      if (profile?.themePreference != null) {
        ref
            .read(themeModeProvider.notifier)
            .setFromPreference(profile!.themePreference!.wireName);
      }
    });
    return child;
  }
}
