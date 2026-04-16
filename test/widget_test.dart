import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finko/app/app_routes.dart';
import 'package:finko/app/finko_app.dart';
import 'package:finko/app/router.dart';
import 'package:finko/core/app_environment.dart';
import 'package:finko/core/locale/app_environment_provider.dart';
import 'package:finko/core/user_profile/user_locale_repository.dart';

import 'fake_user_locale_repository.dart';

void main() {
  testWidgets('app loads with Spanish default locale', (tester) async {
    final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(AppEnvironment.dev),
          userLocaleRepositoryProvider.overrideWithValue(
            FakeUserLocaleRepository(),
          ),
          goRouterProvider.overrideWithValue(
            GoRouter(
              navigatorKey: rootKey,
              initialLocation: '/dashboard',
              routes: buildAppRoutes(rootNavigatorKey: rootKey),
            ),
          ),
        ],
        child: const FinkoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Panel')),
      findsOneWidget,
    );
    expect(find.text('[DEV]'), findsOneWidget);
  });

  testWidgets('English locale shows Dashboard title', (tester) async {
    final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(AppEnvironment.dev),
          userLocaleRepositoryProvider.overrideWithValue(
            FakeUserLocaleRepository(initial: const Locale('en')),
          ),
          goRouterProvider.overrideWithValue(
            GoRouter(
              navigatorKey: rootKey,
              initialLocation: '/dashboard',
              routes: buildAppRoutes(rootNavigatorKey: rootKey),
            ),
          ),
        ],
        child: const FinkoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Dashboard'),
      ),
      findsOneWidget,
    );
  });
}
