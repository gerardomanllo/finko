import 'package:flutter/material.dart';

import '../../core/data/models/finko_enums.dart';
import '../../l10n/app_localizations.dart';

/// Three-way theme control (light / dark / match system) with icons.
class FinkoThemeModeToggle extends StatelessWidget {
  const FinkoThemeModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  final ThemePreference value;
  final ValueChanged<ThemePreference> onChanged;
  final AppLocalizations l10n;

  static const _order = [
    ThemePreference.light,
    ThemePreference.dark,
    ThemePreference.system,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final pref in _order)
              Expanded(
                child: Tooltip(
                  message: _label(l10n, pref),
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: pref == value
                          ? scheme.primaryContainer
                          : null,
                      foregroundColor: pref == value
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                    onPressed: () => onChanged(pref),
                    icon: Icon(_icon(pref)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _icon(ThemePreference p) => switch (p) {
    ThemePreference.light => Icons.light_mode_outlined,
    ThemePreference.dark => Icons.dark_mode_outlined,
    ThemePreference.system => Icons.brightness_auto_outlined,
  };

  static String _label(AppLocalizations l10n, ThemePreference p) => switch (p) {
    ThemePreference.light => l10n.themeLight,
    ThemePreference.dark => l10n.themeDark,
    ThemePreference.system => l10n.themeSystem,
  };
}
