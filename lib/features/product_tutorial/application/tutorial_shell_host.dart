import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shell callbacks registered by [AppShell] for tour navigation.
class TutorialShellHost {
  const TutorialShellHost({
    required this.openDrawer,
    required this.closeDrawer,
    required this.navigationShell,
    required this.scaffoldKey,
    this.scrollDashboardToTop,
  });

  final VoidCallback openDrawer;
  final VoidCallback closeDrawer;
  final StatefulNavigationShell navigationShell;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback? scrollDashboardToTop;
}

final tutorialShellHostProvider =
    StateProvider<TutorialShellHost?>((ref) => null);

/// Dashboard [ListView] controller registered while the dashboard tab is mounted.
final dashboardScrollControllerProvider =
    StateProvider<ScrollController?>((ref) => null);
