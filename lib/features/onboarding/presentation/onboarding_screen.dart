import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/language_locale_dropdown.dart';

/// Step 1 of onboarding: profile & preferences ([`onboarding.md`]), including
/// language / locale ([`language-and-localization.md`]).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _displayNameController = TextEditingController(text: '');
  String _timezone = 'America/Mexico_City';
  String _themeChoice = 'system';

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginErrorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingStep1Title)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                children: [
                  LinearProgressIndicator(value: 1 / 9),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingDisplayNameLabel,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_timezone),
                    initialValue: _timezone,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingTimezoneLabel,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'America/Mexico_City',
                        child: Text('America/Mexico_City'),
                      ),
                      DropdownMenuItem(
                        value: 'America/New_York',
                        child: Text('America/New_York'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _timezone = v ?? _timezone),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_themeChoice),
                    initialValue: _themeChoice,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingThemeLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'light',
                        child: Text(l10n.themeLight),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Text(l10n.themeDark),
                      ),
                      DropdownMenuItem(
                        value: 'system',
                        child: Text(l10n.themeSystem),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _themeChoice = v ?? _themeChoice),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.onboardingLocaleLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const LanguageLocaleDropdown(),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text(l10n.onboardingNext),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: OutlinedButton(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                ),
                child: Text(l10n.settingsSignOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
