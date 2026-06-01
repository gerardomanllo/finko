import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'finko_tutorial_overlay.dart';

/// Wraps the app to show the tour overlay above routed content.
class ProductTutorialHost extends ConsumerWidget {
  const ProductTutorialHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const FinkoTutorialOverlay(),
      ],
    );
  }
}
