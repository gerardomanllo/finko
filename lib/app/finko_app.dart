import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/finko_theme.dart';
import '../l10n/app_localizations.dart';
import '../core/locale/locale_notifier.dart';
import '../core/locale/locale_support.dart';
import 'materialize_listener.dart';
import 'router.dart';

class FinkoApp extends ConsumerWidget {
  const FinkoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final asyncLocale = ref.watch(localeNotifierProvider);
    final locale = asyncLocale.asData?.value ?? kDefaultAppLocale;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: FinkoTheme.light(),
      darkTheme: FinkoTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) => MaterializeDueUpcomingListener(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
