import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finko/features/onboarding/application/onboarding_controller.dart';
import 'package:finko/features/onboarding/domain/onboarding_models.dart';

void main() {
  test('cannot advance from accounts step without accounts', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(onboardingControllerProvider.notifier);
    controller.updateProfile(
      displayName: 'Gerardo',
      timezone: 'America/Mexico_City',
      themePreference: 'system',
      locale: 'es',
    );
    await controller.next();
    expect(
      container.read(onboardingControllerProvider).step,
      OnboardingStep.accounts,
    );

    final ok = await controller.next();
    expect(ok, isFalse);
    expect(
      container.read(onboardingControllerProvider).validationCode,
      'accountsMinOne',
    );
  });
}
