import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/presentation/accounts_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/spending/presentation/spending_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';

List<RouteBase> buildAppRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  return <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) =>
          const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) {
            return AppShell(navigationShell: navigationShell);
          },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) =>
                  const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/recurring',
              builder: (BuildContext context, GoRouterState state) =>
                  const RecurringScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/spending',
              builder: (BuildContext context, GoRouterState state) =>
                  const SpendingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/transactions',
              builder: (BuildContext context, GoRouterState state) =>
                  const TransactionsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/budgets',
      builder: (BuildContext context, GoRouterState state) =>
          const BudgetsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/categories',
      builder: (BuildContext context, GoRouterState state) =>
          const CategoriesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/accounts',
      builder: (BuildContext context, GoRouterState state) =>
          const AccountsScreen(),
    ),
  ];
}
