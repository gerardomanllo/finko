import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/user_profile.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../onboarding/presentation/onboarding_messaging_sheet.dart';
import '../../../widgets/language_locale_dropdown.dart';
import '../../../widgets/layout/finko_settings_section.dart';
import '../../../widgets/settings/finko_theme_mode_toggle.dart';
import '../data/user_settings_writer.dart';
import 'settings_messaging_sheets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static bool _whatsappLinked(UserProfile? p) =>
      p?.integrations.whatsapp != null;

  static bool _telegramLinked(UserProfile? p) =>
      p?.integrations.telegram != null;

  Future<void> _persistTheme(
    BuildContext context,
    WidgetRef ref,
    ThemePreference pref,
  ) async {
    ref.read(themeModeProvider.notifier).setFromPreference(pref.wireName);
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(userSettingsWriterProvider).setThemePreference(uid, pref);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsErrorSave)));
      }
    }
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (profile == null) return;
    if (_whatsappLinked(profile)) {
      await showSettingsMessagingConnectedSheet(
        context: context,
        l10n: l10n,
        channel: 'whatsapp',
        profile: profile,
        onDisconnect: () => _confirmDisconnect(context, ref, 'whatsapp'),
      );
      return;
    }
    await showOnboardingMessagingChannelSheet(
      context: context,
      l10n: l10n,
      channel: 'whatsapp',
      initialIdentity: '',
      onRequestOtp: (id) => ref
          .read(onboardingRepositoryProvider)
          .requestMessagingOtp(channel: 'whatsapp', identity: id),
      onVerify: (id, code) async {
        await ref
            .read(onboardingRepositoryProvider)
            .verifyMessagingOtp(
              channel: 'whatsapp',
              identity: id,
              otpCode: code,
            );
        ref.invalidate(userProfileStreamProvider);
      },
    );
  }

  Future<void> _openTelegram(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (profile == null) return;
    if (_telegramLinked(profile)) {
      await showSettingsMessagingConnectedSheet(
        context: context,
        l10n: l10n,
        channel: 'telegram',
        profile: profile,
        onDisconnect: () => _confirmDisconnect(context, ref, 'telegram'),
      );
      return;
    }
    await showOnboardingMessagingChannelSheet(
      context: context,
      l10n: l10n,
      channel: 'telegram',
      initialIdentity: '',
      onRequestOtp: (id) => ref
          .read(onboardingRepositoryProvider)
          .requestMessagingOtp(channel: 'telegram', identity: id),
      onVerify: (id, code) async {
        await ref
            .read(onboardingRepositoryProvider)
            .verifyMessagingOtp(
              channel: 'telegram',
              identity: id,
              otpCode: code,
            );
        ref.invalidate(userProfileStreamProvider);
      },
    );
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    WidgetRef ref,
    String channel,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsMessagingDisconnectConfirmTitle),
        content: Text(l10n.settingsMessagingDisconnectConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.settingsMessagingDisconnectCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsMessagingDisconnectConfirmCta),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    try {
      await ref
          .read(userSettingsWriterProvider)
          .clearMessagingIntegration(uid, channel);
      ref.invalidate(userProfileStreamProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsErrorSave)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final themePref = switch (ref.watch(themeModeProvider)) {
      ThemeMode.light => ThemePreference.light,
      ThemeMode.dark => ThemePreference.dark,
      ThemeMode.system => ThemePreference.system,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FinkoSettingsSection(
            title: l10n.settingsAppearanceSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.settingsThemeLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FinkoThemeModeToggle(
                  value: themePref,
                  l10n: l10n,
                  onChanged: (p) => _persistTheme(context, ref, p),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FinkoSettingsSection(
            title: l10n.settingsLanguageSection,
            child: const LanguageLocaleDropdown(),
          ),
          const SizedBox(height: 24),
          FinkoSettingsSection(
            title: l10n.settingsMembershipSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.tonal(
                  onPressed: null,
                  child: Text(l10n.settingsManagePlan),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    l10n.settingsComingSoonLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsManagePlanSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FinkoSettingsSection(
            title: l10n.settingsMessagingSection,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.chat_outlined,
                    color: Color(0xFF25D366),
                  ),
                  title: Text(l10n.settingsMessagingWhatsApp),
                  subtitle: Text(
                    _whatsappLinked(profile)
                        ? l10n.settingsMessagingStatusConnected
                        : l10n.settingsMessagingStatusNotConnected,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: profile == null
                      ? null
                      : () => _openWhatsApp(context, ref, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.telegram, color: Color(0xFF0088CC)),
                  title: Text(l10n.settingsMessagingTelegram),
                  subtitle: Text(
                    _telegramLinked(profile)
                        ? l10n.settingsMessagingStatusConnected
                        : l10n.settingsMessagingStatusNotConnected,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: profile == null
                      ? null
                      : () => _openTelegram(context, ref, profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: () async {
              try {
                await ref.read(authRepositoryProvider).signOut();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.loginErrorGeneric)),
                  );
                }
              }
            },
            child: Text(l10n.settingsSignOut),
          ),
        ],
      ),
    );
  }
}
