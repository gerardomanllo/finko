import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/language_locale_dropdown.dart';
import '../../../widgets/layout/finko_settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FinkoSettingsSection(
            title: l10n.settingsLanguageSection,
            child: const LanguageLocaleDropdown(),
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
