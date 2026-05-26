import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finko/features/onboarding/application/onboarding_controller.dart';
import 'package:finko/features/onboarding/domain/onboarding_models.dart';

void main() {
  test('can advance from accounts step with default system cash', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(onboardingControllerProvider.notifier);
    controller.updateProfile(
      displayName: 'Gerardo',
      timezone: 'America/Mexico_City',
      themePreference: 'system',
      locale: 'es',
      mainCurrency: 'MXN',
    );
    await controller.next(); // welcome -> profile
    await controller.next(); // profile -> accounts
    expect(
      container.read(onboardingControllerProvider).step,
      OnboardingStep.accounts,
    );

    final ok = await controller.next();
    expect(ok, isTrue);
    expect(
      container.read(onboardingControllerProvider).step,
      OnboardingStep.categories,
    );
  });

  test('system cash account cannot be removed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(onboardingControllerProvider.notifier);
    final before = container.read(onboardingControllerProvider).draft.accounts;
    expect(
      before.any((a) => a.id == OnboardingDraft.kSystemCashAccountId),
      isTrue,
    );

    controller.removeAccount(OnboardingDraft.kSystemCashAccountId);
    final after = container.read(onboardingControllerProvider).draft.accounts;
    expect(after.length, before.length);
  });

  test(
    'budgets step seeds income category from recurring in one state update',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(onboardingControllerProvider.notifier);
      controller.updateProfile(
        displayName: 'Test User',
        timezone: 'America/Mexico_City',
        themePreference: 'system',
        locale: 'es',
        mainCurrency: 'MXN',
      );
      await controller.next(); // welcome -> profile
      await controller.next(); // profile -> accounts
      await controller.next(); // accounts -> categories

      controller.addSuggestedCategory(
        id: 'salary',
        name: 'Salary',
        kind: OnboardingCategoryKind.income,
        iconKey: 'work',
      );
      controller.addSuggestedCategory(
        id: 'food',
        name: 'Food',
        kind: OnboardingCategoryKind.expense,
        iconKey: 'restaurant',
      );
      await controller.next(); // recurringIncome
      controller.setRecurring(
        OnboardingRecurringIncomeDraft(
          categoryId: 'salary',
          isRecurring: true,
          amountMinor: 25_000,
          accountId: OnboardingDraft.kSystemCashAccountId,
          daysOfMonth: const [1],
          cadence: OnboardingCadence.monthly,
        ),
      );

      await controller.next(); // budgets

      final state = container.read(onboardingControllerProvider);
      expect(state.step, OnboardingStep.budgets);
      expect(state.draft.budgetsMinorByCategory['salary'], 25_000);
    },
  );

  test('setRecurring overwrites income budget whenever recurring changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(onboardingControllerProvider.notifier);
    controller.addSuggestedCategory(
      id: 'salary',
      name: 'Salary',
      kind: OnboardingCategoryKind.income,
      iconKey: 'work',
    );
    controller.setRecurring(
      OnboardingRecurringIncomeDraft(
        categoryId: 'salary',
        isRecurring: true,
        amountMinor: 10_000,
        accountId: OnboardingDraft.kSystemCashAccountId,
        daysOfMonth: const [1],
        cadence: OnboardingCadence.monthly,
      ),
    );
    expect(
      container
          .read(onboardingControllerProvider)
          .draft
          .budgetsMinorByCategory['salary'],
      10_000,
    );
    controller.setBudget('salary', 999_999);
    controller.setRecurring(
      OnboardingRecurringIncomeDraft(
        categoryId: 'salary',
        isRecurring: true,
        amountMinor: 20_000,
        accountId: OnboardingDraft.kSystemCashAccountId,
        daysOfMonth: const [1],
        cadence: OnboardingCadence.monthly,
      ),
    );
    expect(
      container
          .read(onboardingControllerProvider)
          .draft
          .budgetsMinorByCategory['salary'],
      20_000,
    );
  });
}
