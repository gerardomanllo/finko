import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finko/features/product_tutorial/application/product_tutorial_controller.dart';
import 'package:finko/features/product_tutorial/domain/tutorial_catalog.dart';

void main() {
  test('start activates tour at step 0', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(productTutorialControllerProvider.notifier).start();
    final state = container.read(productTutorialControllerProvider);
    expect(state.active, isTrue);
    expect(state.stepIndex, 0);
    expect(state.currentStep?.id, kProductTutorialCatalog.first.id);
  });

  test('previous decrements step when active', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(productTutorialControllerProvider.notifier);
    await notifier.start();
    await notifier.next();
    expect(container.read(productTutorialControllerProvider).stepIndex, 1);
    await notifier.previous();
    expect(container.read(productTutorialControllerProvider).stepIndex, 0);
  });

  test('canGoBack is false on first step', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(productTutorialControllerProvider.notifier).start();
    expect(
      container.read(productTutorialControllerProvider).canGoBack,
      isFalse,
    );
  });

  test('skip deactivates tour', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(productTutorialControllerProvider.notifier).start();
    await container.read(productTutorialControllerProvider.notifier).skip();
    expect(container.read(productTutorialControllerProvider).active, isFalse);
  });
}
