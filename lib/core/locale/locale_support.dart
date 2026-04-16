import 'package:flutter/material.dart';

/// Default UI language is Spanish (see docs/language-and-localization.md).
const Locale kDefaultAppLocale = Locale('es');

/// Supported BCP 47 tags for the language picker; extend when adding regions.
const List<String> kSupportedLocaleTags = ['es', 'en'];

Locale normalizeAppLocale(Locale locale) {
  final code = locale.languageCode.toLowerCase();
  if (code == 'en') return const Locale('en');
  return kDefaultAppLocale;
}

/// Parses a BCP 47 tag (e.g. `es-MX`, `en`) to a [Locale]. Unsupported
/// languages fall back to Spanish.
Locale localeFromBcp47(String tag) {
  final trimmed = tag.trim();
  if (trimmed.isEmpty) return kDefaultAppLocale;
  final parts = trimmed.replaceAll('_', '-').split('-');
  final language = parts.first.toLowerCase();
  if (language == 'en') {
    if (parts.length >= 2 && parts[1].length == 2) {
      return Locale.fromSubtags(
        languageCode: 'en',
        countryCode: parts[1].toUpperCase(),
      );
    }
    return const Locale('en');
  }
  if (language == 'es') {
    if (parts.length >= 2 && parts[1].length == 2) {
      return Locale.fromSubtags(
        languageCode: 'es',
        countryCode: parts[1].toUpperCase(),
      );
    }
    return kDefaultAppLocale;
  }
  return kDefaultAppLocale;
}

String localeToBcp47(Locale locale) {
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
    return '${locale.languageCode}-${locale.countryCode}';
  }
  return locale.languageCode;
}
