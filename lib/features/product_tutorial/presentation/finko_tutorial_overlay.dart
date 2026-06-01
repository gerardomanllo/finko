import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/product_tutorial_controller.dart';
import '../application/tutorial_navigation.dart';
import '../application/tutorial_target_registry.dart';
import '../domain/tutorial_step.dart';
import 'tutorial_l10n.dart';

class FinkoTutorialOverlay extends ConsumerStatefulWidget {
  const FinkoTutorialOverlay({super.key});

  @override
  ConsumerState<FinkoTutorialOverlay> createState() =>
      _FinkoTutorialOverlayState();
}

class _FinkoTutorialOverlayState extends ConsumerState<FinkoTutorialOverlay> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  void _remeasure() {
    if (!mounted) return;
    final step = ref.read(productTutorialControllerProvider).currentStep;
    final id = step?.targetId;
    Rect? rect;
    if (id != null) {
      rect = ref.read(tutorialTargetRegistryProvider.notifier).rectFor(id);
    }
    if (rect != _targetRect) {
      setState(() => _targetRect = rect);
    }
    if (id != null && rect == null) {
      _scheduleRemeasureRetries();
    }
  }

  void _scheduleRemeasureRetries() {
    for (final ms in const [80, 160, 280, 420, 600]) {
      Future<void>.delayed(Duration(milliseconds: ms), () {
        if (!mounted) return;
        _remeasure();
      });
    }
  }

  Rect? _holeFor(TutorialStep step, Rect? rect, Size screenSize) {
    if (rect == null) return null;
    var hole = rect.inflate(step.spotlightPadding);
    final maxH = step.maxSpotlightHeight;
    final maxW = step.maxSpotlightWidth ?? screenSize.width - 32;
    if (maxH != null && hole.height > maxH) {
      final w = hole.width.clamp(48.0, maxW).toDouble();
      hole = Rect.fromLTWH(
        hole.left + (hole.width - w) / 2,
        hole.top,
        w,
        maxH,
      );
    }
    if (hole.width > maxW) {
      final h = hole.height;
      hole = Rect.fromLTWH(
        hole.left + (hole.width - maxW) / 2,
        hole.top,
        maxW,
        h,
      );
    }
    return hole;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(productTutorialControllerProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    });
    ref.listen(tutorialScrollTickProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    });

    final tour = ref.watch(productTutorialControllerProvider);
    if (!tour.active) return const SizedBox.shrink();

    final step = tour.currentStep;
    if (step == null) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    if (step.targetId != null && _targetRect == null) {
      _scheduleRemeasureRetries();
    }

    final l10n = AppLocalizations.of(context);
    final title = tutorialString(l10n, step.titleKey);
    final body = tutorialString(l10n, step.bodyKey);
    final screenSize = MediaQuery.sizeOf(context);
    final hole = step.spotlightShape == TutorialSpotlightShape.none
        ? null
        : _holeFor(step, _targetRect, screenSize);
    final cardLayout = _TooltipLayout.compute(
      context: context,
      hole: hole,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TutorialScrimPainter(
                hole: hole,
                shape: step.spotlightShape,
              ),
            ),
          ),
          if (cardLayout != null)
            Positioned(
              top: cardLayout.top,
              bottom: cardLayout.bottom,
              left: 16,
              right: 16,
              child: Align(
                alignment: cardLayout.align,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardLayout.maxWidth,
                  ),
                  child: Semantics(
                    header: true,
                    label: '$title. $body',
                    child: _TutorialTooltipCard(
                      title: title,
                      body: body,
                      stepIndex: tour.stepIndex + 1,
                      totalSteps: tour.totalSteps,
                      canGoBack: tour.canGoBack,
                      isLast: tour.isLastStep,
                      onBack: () => ref
                          .read(productTutorialControllerProvider.notifier)
                          .previous(),
                      onNext: () async {
                        final notifier = ref.read(
                          productTutorialControllerProvider.notifier,
                        );
                        if (tour.isLastStep) {
                          await notifier.complete();
                        } else {
                          await notifier.next();
                        }
                      },
                      onSkip: () => ref
                          .read(productTutorialControllerProvider.notifier)
                          .skip(),
                      backLabel: l10n.tutorialBack,
                      nextLabel: tour.isLastStep
                          ? l10n.tutorialDone
                          : l10n.tutorialNext,
                      skipLabel: l10n.tutorialSkip,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TooltipLayout {
  const _TooltipLayout({
    this.top,
    this.bottom,
    required this.align,
    required this.maxWidth,
  });

  final double? top;
  final double? bottom;
  final Alignment align;
  final double maxWidth;

  static _TooltipLayout? compute({
    required BuildContext context,
    required Rect? hole,
  }) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final maxWidth = (size.width - 32).clamp(240.0, 320.0);

    if (hole == null) {
      return _TooltipLayout(
        bottom: padding.bottom + 20,
        align: Alignment.bottomCenter,
        maxWidth: maxWidth,
      );
    }

    const gap = 6.0;
    const cardEstimate = 168.0;
    final spaceBelow =
        size.height - padding.bottom - hole.bottom - gap;
    final spaceAbove = hole.top - padding.top - gap;

    if (spaceBelow >= cardEstimate || spaceBelow >= spaceAbove) {
      return _TooltipLayout(
        top: (hole.bottom + gap).clamp(
          padding.top,
          size.height - padding.bottom - cardEstimate,
        ),
        align: Alignment.topCenter,
        maxWidth: maxWidth,
      );
    }
    return _TooltipLayout(
      bottom: size.height - hole.top + gap,
      align: Alignment.bottomCenter,
      maxWidth: maxWidth,
    );
  }
}

class _TutorialTooltipCard extends StatelessWidget {
  const _TutorialTooltipCard({
    required this.title,
    required this.body,
    required this.stepIndex,
    required this.totalSteps,
    required this.canGoBack,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.backLabel,
    required this.nextLabel,
    required this.skipLabel,
  });

  final String title;
  final String body;
  final int stepIndex;
  final int totalSteps;
  final bool canGoBack;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String backLabel;
  final String nextLabel;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 10,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              '$stepIndex / $totalSteps',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(onPressed: onSkip, child: Text(skipLabel)),
                if (canGoBack) ...[
                  TextButton(onPressed: onBack, child: Text(backLabel)),
                ],
                const Spacer(),
                FilledButton(onPressed: onNext, child: Text(nextLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialScrimPainter extends CustomPainter {
  _TutorialScrimPainter({required this.hole, required this.shape});

  final Rect? hole;
  final TutorialSpotlightShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.88);
    final full = Path()..addRect(Offset.zero & size);
    if (hole == null) {
      canvas.drawPath(full, scrim);
      return;
    }
    final holePath = Path();
    switch (shape) {
      case TutorialSpotlightShape.circle:
        holePath.addOval(
          Rect.fromCircle(
            center: hole!.center,
            radius: hole!.shortestSide / 2 + 6,
          ),
        );
      case TutorialSpotlightShape.pill:
        final r = Radius.circular(hole!.height / 2);
        holePath.addRRect(RRect.fromRectAndRadius(hole!, r));
      case TutorialSpotlightShape.roundedRect:
        holePath.addRRect(
          RRect.fromRectAndRadius(hole!, const Radius.circular(12)),
        );
      case TutorialSpotlightShape.none:
        break;
    }
    final combined = Path.combine(PathOperation.difference, full, holePath);
    canvas.drawPath(combined, scrim);
  }

  @override
  bool shouldRepaint(covariant _TutorialScrimPainter oldDelegate) {
    return oldDelegate.hole != hole || oldDelegate.shape != shape;
  }
}
