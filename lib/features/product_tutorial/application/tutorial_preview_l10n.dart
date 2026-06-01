import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/locale_notifier.dart';
import '../../../core/locale/locale_support.dart';
import '../../../l10n/app_localizations.dart';

/// Resolves tutorial-only preview copy in the active app locale (EN/ES).
String tutorialPreviewString(
  Ref ref,
  String Function(AppLocalizations l10n) pick,
) {
  final asyncLocale = ref.read(localeNotifierProvider);
  final locale = asyncLocale.asData?.value ?? kDefaultAppLocale;
  return pick(lookupAppLocalizations(locale));
}
