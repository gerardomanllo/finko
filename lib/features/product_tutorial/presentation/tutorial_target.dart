import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/tutorial_target_registry.dart';
import '../domain/tutorial_target_id.dart';

/// Registers [child] for spotlight measurement under [id].
class TutorialTarget extends ConsumerStatefulWidget {
  const TutorialTarget({
    super.key,
    required this.id,
    required this.child,
  });

  final TutorialTargetId id;
  final Widget child;

  @override
  ConsumerState<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends ConsumerState<TutorialTarget> {
  @override
  Widget build(BuildContext context) {
    final key =
        ref.read(tutorialTargetRegistryProvider.notifier).keyFor(widget.id);
    return KeyedSubtree(key: key, child: widget.child);
  }
}
