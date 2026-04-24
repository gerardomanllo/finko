import 'package:flutter/material.dart';

/// Named ARGB color for account dropdowns.
///
/// **Why a map (not hex):** users picking an account color want a memorable label like
/// "Ocean blue" / "Azul océano", not `#1565C0`. `id` is a stable key for persistence,
/// not shown in the UI.
@immutable
class OnboardingNamedColor {
  const OnboardingNamedColor({
    required this.id,
    required this.argb,
    required this.en,
    required this.es,
  });

  final String id;
  final int argb;
  final String en;
  final String es;
}

/// Curated palette ordered like a rainbow (red → violet) so the dropdown reads naturally.
const List<OnboardingNamedColor>
kOnboardingNamedColors = <OnboardingNamedColor>[
  OnboardingNamedColor(
    id: 'crimson',
    argb: 0xFFC62828,
    en: 'Crimson',
    es: 'Carmesí',
  ),
  OnboardingNamedColor(id: 'red', argb: 0xFFF44336, en: 'Red', es: 'Rojo'),
  OnboardingNamedColor(id: 'coral', argb: 0xFFFF5722, en: 'Coral', es: 'Coral'),
  OnboardingNamedColor(
    id: 'orange',
    argb: 0xFFFF9800,
    en: 'Orange',
    es: 'Naranja',
  ),
  OnboardingNamedColor(id: 'amber', argb: 0xFFFFC107, en: 'Amber', es: 'Ámbar'),
  OnboardingNamedColor(
    id: 'yellow',
    argb: 0xFFFDD835,
    en: 'Yellow',
    es: 'Amarillo',
  ),
  OnboardingNamedColor(id: 'lime', argb: 0xFFCDDC39, en: 'Lime', es: 'Lima'),
  OnboardingNamedColor(id: 'olive', argb: 0xFF9E9D24, en: 'Olive', es: 'Oliva'),
  OnboardingNamedColor(id: 'green', argb: 0xFF4CAF50, en: 'Green', es: 'Verde'),
  OnboardingNamedColor(
    id: 'emerald',
    argb: 0xFF2E7D32,
    en: 'Emerald',
    es: 'Esmeralda',
  ),
  OnboardingNamedColor(
    id: 'teal',
    argb: 0xFF009688,
    en: 'Teal',
    es: 'Verde azulado',
  ),
  OnboardingNamedColor(id: 'cyan', argb: 0xFF00BCD4, en: 'Cyan', es: 'Cian'),
  OnboardingNamedColor(
    id: 'sky',
    argb: 0xFF0288D1,
    en: 'Sky blue',
    es: 'Azul cielo',
  ),
  OnboardingNamedColor(id: 'blue', argb: 0xFF2196F3, en: 'Blue', es: 'Azul'),
  OnboardingNamedColor(
    id: 'navy',
    argb: 0xFF1A237E,
    en: 'Navy',
    es: 'Azul marino',
  ),
  OnboardingNamedColor(
    id: 'indigo',
    argb: 0xFF3F51B5,
    en: 'Indigo',
    es: 'Índigo',
  ),
  OnboardingNamedColor(
    id: 'violet',
    argb: 0xFF673AB7,
    en: 'Violet',
    es: 'Violeta',
  ),
  OnboardingNamedColor(
    id: 'purple',
    argb: 0xFF9C27B0,
    en: 'Purple',
    es: 'Morado',
  ),
  OnboardingNamedColor(
    id: 'magenta',
    argb: 0xFFAD1457,
    en: 'Magenta',
    es: 'Magenta',
  ),
  OnboardingNamedColor(id: 'pink', argb: 0xFFE91E63, en: 'Pink', es: 'Rosa'),
  OnboardingNamedColor(id: 'brown', argb: 0xFF795548, en: 'Brown', es: 'Café'),
  OnboardingNamedColor(
    id: 'slate',
    argb: 0xFF607D8B,
    en: 'Slate',
    es: 'Pizarra',
  ),
  OnboardingNamedColor(
    id: 'graphite',
    argb: 0xFF37474F,
    en: 'Graphite',
    es: 'Grafito',
  ),
  OnboardingNamedColor(
    id: 'charcoal',
    argb: 0xFF424242,
    en: 'Charcoal',
    es: 'Carbón',
  ),
];

String onboardingColorLabel(OnboardingNamedColor c, Locale locale) {
  return locale.languageCode == 'es' ? c.es : c.en;
}

/// Nearest named color by RGB distance. Lets us show a label even when a legacy account
/// was saved with an unrelated ARGB value.
OnboardingNamedColor onboardingNearestNamedColor(int argb) {
  for (final c in kOnboardingNamedColors) {
    if (c.argb == argb) return c;
  }
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  OnboardingNamedColor best = kOnboardingNamedColors.first;
  var bestD = 1 << 30;
  for (final c in kOnboardingNamedColors) {
    final cr = (c.argb >> 16) & 0xFF;
    final cg = (c.argb >> 8) & 0xFF;
    final cb = c.argb & 0xFF;
    final dr = cr - r;
    final dg = cg - g;
    final db = cb - b;
    final d = dr * dr + dg * dg + db * db;
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  return best;
}
