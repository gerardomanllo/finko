import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../data/product_tutorial_preference.dart';
import '../domain/tutorial_catalog.dart';
import '../domain/tutorial_step.dart';
import 'tutorial_navigation.dart';

class ProductTutorialState {
  const ProductTutorialState({
    this.active = false,
    this.stepIndex = 0,
  });

  final bool active;
  final int stepIndex;

  TutorialStep? get currentStep {
    if (!active || stepIndex < 0 || stepIndex >= kProductTutorialCatalog.length) {
      return null;
    }
    return kProductTutorialCatalog[stepIndex];
  }

  int get totalSteps => kProductTutorialCatalog.length;

  bool get isLastStep => stepIndex >= kProductTutorialCatalog.length - 1;

  bool get canGoBack => active && stepIndex > 0;

  ProductTutorialState copyWith({bool? active, int? stepIndex}) {
    return ProductTutorialState(
      active: active ?? this.active,
      stepIndex: stepIndex ?? this.stepIndex,
    );
  }
}

final productTutorialControllerProvider =
    NotifierProvider<ProductTutorialController, ProductTutorialState>(
      ProductTutorialController.new,
    );

final productTutorialActiveProvider = Provider<bool>(
  (ref) => ref.watch(productTutorialControllerProvider).active,
);

class ProductTutorialController extends Notifier<ProductTutorialState> {
  @override
  ProductTutorialState build() => const ProductTutorialState();

  Future<void> start() async {
    state = const ProductTutorialState(active: true, stepIndex: 0);
    await _prepareCurrent();
  }

  Future<void> next() async {
    if (!state.active) return;
    var nextIndex = state.stepIndex + 1;
    while (nextIndex < kProductTutorialCatalog.length) {
      final step = kProductTutorialCatalog[nextIndex];
      if (step.skipWhen != null && step.skipWhen!(ref)) {
        nextIndex++;
        continue;
      }
      break;
    }
    if (nextIndex >= kProductTutorialCatalog.length) {
      await complete();
      return;
    }
    state = state.copyWith(stepIndex: nextIndex);
    await _prepareCurrent();
  }

  Future<void> previous() async {
    if (!state.active || state.stepIndex <= 0) return;
    var prevIndex = state.stepIndex - 1;
    while (prevIndex >= 0) {
      final step = kProductTutorialCatalog[prevIndex];
      if (step.skipWhen != null && step.skipWhen!(ref)) {
        prevIndex--;
        continue;
      }
      break;
    }
    if (prevIndex < 0) return;
    state = state.copyWith(stepIndex: prevIndex);
    await _prepareCurrent();
  }

  Future<void> skip() async {
    await _markCompleted();
    await resetTourHome(ref);
    state = const ProductTutorialState();
  }

  Future<void> complete() async {
    await _markCompleted();
    await resetTourHome(ref);
    state = const ProductTutorialState();
  }

  Future<void> _prepareCurrent() async {
    final step = state.currentStep;
    if (step == null) return;
    if (step.skipWhen != null && step.skipWhen!(ref)) {
      await next();
      return;
    }
    await prepareTutorialStep(ref, step);
  }

  Future<void> _markCompleted() async {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    await setProductTourCompleted(
      firestore: ref.read(firestoreProvider),
      uid: uid,
    );
    ref.invalidate(productTourCompletedProvider);
  }
}
