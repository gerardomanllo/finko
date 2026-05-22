import 'package:flutter_test/flutter_test.dart';
import 'package:finko/features/onboarding/domain/onboarding_models.dart';

void main() {
  test(
    'toCommitPayload includes mainCurrency and budgets for commitOnboarding',
    () {
      final draft = OnboardingDraft(
        displayName: '  Ada  ',
        mainCurrency: 'USD',
        accounts: const [
          OnboardingAccountDraft(
            id: 'a1',
            name: 'Checking',
            type: OnboardingAccountType.checking,
            currency: 'eur',
            colorArgb: 0,
            startingBalanceMinor: 0,
            iconKey: 'account_balance',
            isSystem: false,
          ),
        ],
        categories: const [
          OnboardingDraft.kFixedExpensesCategory,
          OnboardingCategoryDraft(
            id: 'food',
            name: 'Food',
            kind: OnboardingCategoryKind.expense,
            iconKey: 'restaurant',
            isSystem: false,
          ),
        ],
        budgetsMinorByCategory: const {'fixed-expenses': 100, 'food': 50},
        requestId: 'req-test-1',
      );
      final payload = draft.toCommitPayload();
      expect(payload['requestId'], 'req-test-1');
      expect(payload['budgetsMinorByCategory'], {
        'fixed-expenses': 100,
        'food': 50,
      });
      final profile = payload['profile'] as Map<String, dynamic>;
      expect(profile['displayName'], 'Ada');
      expect(profile['mainCurrency'], 'USD');
    },
  );

  test(
    'onboardingCategoriesForDisplay orders income, fixed, then expenses',
    () {
      const salary = OnboardingCategoryDraft(
        id: 'salary',
        name: 'Salary',
        kind: OnboardingCategoryKind.income,
        iconKey: 'work',
        isSystem: false,
      );
      const food = OnboardingCategoryDraft(
        id: 'food',
        name: 'Food',
        kind: OnboardingCategoryKind.expense,
        iconKey: 'restaurant',
        isSystem: false,
      );
      const transport = OnboardingCategoryDraft(
        id: 'transport',
        name: 'Transport',
        kind: OnboardingCategoryKind.expense,
        iconKey: 'directions_car',
        isSystem: false,
      );
      // Deliberately shuffled input order.
      final sorted = onboardingCategoriesForDisplay([
        food,
        OnboardingDraft.kFixedExpensesCategory,
        transport,
        salary,
      ]);
      expect(sorted.map((c) => c.id).toList(), [
        'salary',
        'fixed-expenses',
        'food',
        'transport',
      ]);
    },
  );

  test('projected savings uses fixed + variable expenses split', () {
    final draft = OnboardingDraft(
      categories: const [
        OnboardingDraft.kFixedExpensesCategory,
        OnboardingCategoryDraft(
          id: 'salary',
          name: 'Salary',
          kind: OnboardingCategoryKind.income,
          iconKey: 'work',
          isSystem: false,
        ),
        OnboardingCategoryDraft(
          id: 'food',
          name: 'Food',
          kind: OnboardingCategoryKind.expense,
          iconKey: 'restaurant',
          isSystem: false,
        ),
      ],
      budgetsMinorByCategory: const {
        'salary': 500000,
        'fixed-expenses': 200000,
        'food': 100000,
      },
    );

    expect(draft.expectedIncomeMinor, 500000);
    expect(draft.fixedExpensesMinor, 200000);
    expect(draft.variableExpensesMinor, 100000);
    expect(draft.projectedSavingsMinor, 200000);
  });
}
