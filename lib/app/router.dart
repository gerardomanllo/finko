import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'auth_redirect.dart';
import '../core/auth/auth_router_refresh.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final AuthRouterRefresh refresh = ref.watch(authRouterRefreshProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: appAuthRedirect,
    routes: buildAppRoutes(rootNavigatorKey: rootNavigatorKey),
  );
});
