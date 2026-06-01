import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tutorial_target_id.dart';

typedef TutorialTargetRegistry = Map<TutorialTargetId, GlobalKey>;

final tutorialTargetRegistryProvider =
    NotifierProvider<TutorialTargetRegistryNotifier, TutorialTargetRegistry>(
      TutorialTargetRegistryNotifier.new,
    );

class TutorialTargetRegistryNotifier extends Notifier<TutorialTargetRegistry> {
  final Map<TutorialTargetId, GlobalKey> _keys = <TutorialTargetId, GlobalKey>{};

  @override
  TutorialTargetRegistry build() => _keys;

  GlobalKey keyFor(TutorialTargetId id) {
    return _keys.putIfAbsent(
      id,
      () => GlobalKey(debugLabel: id.name),
    );
  }

  Rect? rectFor(TutorialTargetId id) {
    final key = _keys[id];
    if (key == null) return null;
    final context = key.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  Future<void> ensureVisible(
    TutorialTargetId id, {
    double alignment = 0.2,
    Duration duration = const Duration(milliseconds: 280),
  }) async {
    final key = _keys[id];
    final context = key?.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: Curves.easeInOut,
      alignment: alignment,
    );
  }
}
