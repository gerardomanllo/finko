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

  testWidgets('shell nav order, plus action, and cog drawer work', (
    tester,
  ) async {
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

    final navBar = find.byType(NavigationBar);
    expect(
      find.descendant(of: navBar, matching: find.text('Panel')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Recurrente')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Nuevo')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Gastos')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Transacciones')),
      findsOneWidget,
    );

    await tester.tap(find.text('Nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva transacción'), findsOneWidget);
    expect(
      find.text('Añade una transacción'),
      findsOneWidget,
    );

    Navigator.of(tester.element(find.text('Nueva transacción'))).pop();
    await tester.pumpAndSettle();

    final settingsButton = find.byTooltip('Abrir menú');
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    expect(find.text('Categorías'), findsAtLeastNWidgets(1));
    expect(find.text('Cuentas'), findsAtLeastNWidgets(1));
    expect(find.text('Ajustes'), findsAtLeastNWidgets(1));
  });
}
