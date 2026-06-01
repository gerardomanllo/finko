import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tutorial_target_id.dart';

enum TutorialPreAction {
  none,
  closeDrawer,
  openDrawer,
  goDashboard,
  goRecurring,
  goSpending,
  goTransactions,
  pushCategories,
  pushAccounts,
  pushBudgets,
  pushSettings,
  popToShellDashboard,
}

enum TutorialSpotlightShape { circle, roundedRect, pill, none }

/// One step in the product tour catalog.
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    this.targetId,
    this.preAction = TutorialPreAction.none,
    this.spotlightShape = TutorialSpotlightShape.roundedRect,
    this.spotlightPadding = 8,
    this.maxSpotlightHeight,
    this.maxSpotlightWidth,
    this.scrollIntoView = true,
    this.skipWhen,
  });

  final String id;
  final String titleKey;
  final String bodyKey;
  final TutorialTargetId? targetId;
  final TutorialPreAction preAction;

  /// Legacy field; navigation uses [id] via [syncNavigationForStep].
  final TutorialSpotlightShape spotlightShape;

  /// Extra inset around measured target rect for the spotlight hole.
  final double spotlightPadding;

  /// Caps spotlight height when the measured target is very tall (e.g. lists).
  final double? maxSpotlightHeight;

  /// Caps spotlight width when the measured target is very wide.
  final double? maxSpotlightWidth;

  /// Whether to call [Scrollable.ensureVisible] before showing the step.
  final bool scrollIntoView;
  final bool Function(Ref ref)? skipWhen;
}
