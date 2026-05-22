import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/user_profile.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/launch/launch_screen_preference.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../onboarding/presentation/onboarding_messaging_sheet.dart';
import '../../../widgets/language_locale_dropdown.dart';
import '../../../widgets/layout/finko_settings_section.dart';
import '../../../widgets/settings/finko_theme_mode_toggle.dart';
import '../data/account_deletion_service.dart';
import '../data/user_settings_writer.dart';
import 'settings_messaging_sheets.dart';
import 'telegram_bot_preferences_sheet.dart';

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
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    await showOnboardingMessagingChannelSheet(
      context: context,
      l10n: l10n,
      channel: 'whatsapp',
      initialIdentity: '',
      firebaseUid: uid,
      firestore: ref.read(firestoreProvider),
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
        onTelegramBotDefaults: () {
          showTelegramBotPreferencesSheet(
            context: context,
            ref: ref,
            profile: profile,
          );
        },
      );
      return;
    }
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    await showOnboardingMessagingChannelSheet(
      context: context,
      l10n: l10n,
      channel: 'telegram',
      initialIdentity: '',
      firebaseUid: uid,
      firestore: ref.read(firestoreProvider),
      onRequestOtp: (id) => ref
          .read(onboardingRepositoryProvider)
          .requestMessagingOtp(channel: 'telegram', identity: id),
      onTelegramLinked: (_) {
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
          .read(onboardingRepositoryProvider)
          .disconnectMessagingIntegration(channel: channel);
      ref.invalidate(userProfileStreamProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsErrorSave)));
      }
    }
  }

  static Future<void> _runDeleteAccountFlow(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authUidProvider);
    if (uid == null) return;

    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountDialog1Title),
        content: Text(l10n.settingsDeleteAccountDialog1Body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.settingsDeleteAccountCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsDeleteAccountContinue),
          ),
        ],
      ),
    );
    if (step1 != true || !context.mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountDialog2Title),
        content: Text(l10n.settingsDeleteAccountDialog2Body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.settingsDeleteAccountCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsDeleteAccountContinue),
          ),
        ],
      ),
    );
    if (step2 != true || !context.mounted) return;

    final step3 = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l10n.settingsDeleteAccountDialog3Title),
          content: Text(l10n.settingsDeleteAccountDialog3Body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.settingsDeleteAccountCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.settingsDeleteAccountConfirmDelete),
            ),
          ],
        );
      },
    );
    if (step3 != true || !context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(l10n.settingsDeleteAccountDeleting)),
            ],
          ),
        ),
      ),
    );

    try {
      await ref.read(accountDeletionServiceProvider).deleteMyAccount();
      if (context.mounted) {
        navigator.pop();
      }
      await ref.read(authRepositoryProvider).signOut();
    } on FirebaseFunctionsException catch (_) {
      if (context.mounted) {
        navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDeleteAccountError)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDeleteAccountError)),
        );
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
            title: l10n.agentTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsLaunchScreenAgent),
                  subtitle: Text(l10n.settingsLaunchScreenDashboard),
                  value: ref.watch(launchScreenPreferenceProvider).maybeWhen(
                    data: (s) => s == LaunchScreen.agent,
                    orElse: () => false,
                  ),
                  onChanged: profile == null
                      ? null
                      : (on) async {
                          final uid = ref.read(authUidProvider);
                          if (uid == null) return;
                          await setLaunchScreenPreference(
                            firestore: ref.read(firestoreProvider),
                            uid: uid,
                            screen: on ? LaunchScreen.agent : LaunchScreen.dashboard,
                          );
                          ref.invalidate(launchScreenPreferenceProvider);
                        },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune_outlined),
                  title: Text(l10n.settingsAgentDefaults),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: profile == null
                      ? null
                      : () => showTelegramBotPreferencesSheet(
                          context: context,
                          ref: ref,
                          profile: profile,
                        ),
                ),
              ],
            ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: ref.watch(authUidProvider) == null
                    ? null
                    : () => _runDeleteAccountFlow(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.settingsDeleteAccount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
