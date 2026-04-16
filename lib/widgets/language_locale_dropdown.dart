import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale/locale_notifier.dart';
import '../core/locale/locale_support.dart';
import '../l10n/app_localizations.dart';

/// Spanish / English selector; updates [localeNotifierProvider] (prefs +
/// `users/{uid}.locale` when signed in).
class LanguageLocaleDropdown extends ConsumerWidget {
  const LanguageLocaleDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncLocale = ref.watch(localeNotifierProvider);
    final locale = asyncLocale.asData?.value ?? kDefaultAppLocale;

    return DropdownButtonFormField<String>(
      key: ValueKey(locale.languageCode),
      initialValue: _tagForDropdown(locale),
      decoration: InputDecoration(labelText: l10n.settingsLanguageLabel),
      items: [
        DropdownMenuItem(value: 'es', child: Text(l10n.localeSpanish)),
        DropdownMenuItem(value: 'en', child: Text(l10n.localeEnglish)),
      ],
      onChanged: (tag) async {
        if (tag == null) return;
        final next = tag == 'en' ? const Locale('en') : kDefaultAppLocale;
        await ref.read(localeNotifierProvider.notifier).setLocale(next);
      },
    );
  }
}

String _tagForDropdown(Locale locale) {
  if (locale.languageCode == 'en') return 'en';
  return 'es';
}
