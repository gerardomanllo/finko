import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circle avatar with border stroke as progress (0–1).
class FinkoCategoryAvatarRing extends StatelessWidget {
  const FinkoCategoryAvatarRing({
    super.key,
    required this.label,
    required this.progress,
    this.ringColor,
  });

  final String label;
  final double progress;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = progress.clamp(0.0, 1.0);
    final color = ringColor ?? theme.colorScheme.primary;
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _RingPainter(progress: p, color: color),
        child: Center(
          child: CircleAvatar(
            radius: 15,
            backgroundColor: theme.colorScheme.surface,
            child: Text(
              label.isNotEmpty ? label[0].toUpperCase() : '?',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ),
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
    final bg = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - 1.5, bg);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.5),
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
