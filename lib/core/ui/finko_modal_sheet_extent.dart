import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Extra space below the status-bar inset so a sliver of the screen behind the
/// sheet stays visible (not edge-to-edge under the status bar).
const double kFinkoModalSheetTopPeek = 12;

/// Max height for [showModalBottomSheet] content when [isScrollControlled] is true.
///
/// Reserves [MediaQuery.padding.top] (status bar / notch) plus [kFinkoModalSheetTopPeek]
/// so the sheet is not full-bleed to the top and the scrim shows a bit of content behind.
///
/// Prefer [layoutMaxHeight] from a [LayoutBuilder] under the sheet [builder] when
/// [constraints.maxHeight] is finite. Always respects the keyboard
/// ([MediaQuery.viewInsets.bottom]) and the top clearance above.
double finkoModalSheetMaxHeight(
  BuildContext context, {
  double? layoutMaxHeight,
}) {
  final mq = MediaQuery.of(context);
  final keyboardSafe = mq.size.height - mq.viewInsets.bottom;
  final topClearance = mq.padding.top + kFinkoModalSheetTopPeek;
  final maxBody = math.max(0.0, keyboardSafe - topClearance);

  if (layoutMaxHeight != null &&
      layoutMaxHeight.isFinite &&
      layoutMaxHeight > 0) {
    return math.min(layoutMaxHeight, maxBody);
  }
  return maxBody;
}
