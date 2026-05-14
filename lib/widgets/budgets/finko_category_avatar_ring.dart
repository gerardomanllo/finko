import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/finko_theme.dart';
import '../categories/finko_category_icon_avatar.dart';

/// Circle with an **outer** progress ring (0–1); center is a **category icon** when
/// [iconKey] + [categoryId] are set, otherwise a **letter** from [label].
class FinkoCategoryAvatarRing extends StatelessWidget {
  const FinkoCategoryAvatarRing({
    super.key,
    required this.label,
    required this.progress,
    this.ringColor,
    this.iconKey,
    this.categoryId,
    this.colorArgb,
    this.cellSize = 46,
    this.innerAvatarRadius = 12,
  });

  /// Fallback initial when not using [iconKey] / [categoryId].
  final String label;
  final double progress;
  final Color? ringColor;

  /// When set with non-empty [categoryId], center shows [FinkoCategoryIconAvatar].
  final String? iconKey;
  final String? categoryId;
  final int? colorArgb;

  /// Outer box (width = height = [cellSize]).
  final double cellSize;

  /// Inner [FinkoCategoryIconAvatar] radius when using icons.
  final double innerAvatarRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = progress.clamp(0.0, 1.0);
    final color = ringColor ?? theme.colorScheme.primary;
    final cid = categoryId?.trim() ?? '';
    final ikey = iconKey?.trim() ?? '';
    final useIcon = cid.isNotEmpty;

    final Widget centerChild = useIcon
        ? FinkoCategoryIconAvatar(
            iconKey: ikey.isNotEmpty ? ikey : 'category',
            categoryId: cid,
            colorArgb: colorArgb,
            radius: innerAvatarRadius,
          )
        : CircleAvatar(
            radius: innerAvatarRadius + 2,
            backgroundColor: theme.colorScheme.surface,
            child: Text(
              label.isNotEmpty ? label[0].toUpperCase() : '?',
              style: theme.textTheme.labelSmall,
            ),
          );

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: CustomPaint(
        painter: _RingPainter(progress: p, color: color),
        child: Center(child: centerChild),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = 2.5;
    final inset = stroke / 2 + 0.5;
    final ringRadius = radius - inset;
    // Track matches `/budgets` compact tiles (`LinearProgressIndicator` +
    // `FinkoColors.grayLight`); foreground is category accent (or primary).
    final bg = Paint()
      ..color = FinkoColors.grayLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, ringRadius, bg);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      start,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
