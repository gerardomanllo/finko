import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/product_tutorial_controller.dart';
import '../data/product_tutorial_preference.dart';

/// Call once on [DashboardScreen] to auto-start the tour when not completed.
class ProductTutorialAutoStart extends ConsumerStatefulWidget {
  const ProductTutorialAutoStart({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProductTutorialAutoStart> createState() =>
      _ProductTutorialAutoStartState();
}

class _ProductTutorialAutoStartState
    extends ConsumerState<ProductTutorialAutoStart> {
  bool _attempted = false;

  @override
  Widget build(BuildContext context) {
    if (!_attempted) {
      _attempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (ref.read(productTutorialControllerProvider).active) return;
        final done = await ref.read(productTourCompletedProvider.future);
        if (done || !mounted) return;
        await ref.read(productTutorialControllerProvider.notifier).start();
      });
    }
    return widget.child;
  }
}
