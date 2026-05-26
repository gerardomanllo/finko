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
          OnboardingCategoryDraft(
            id: 'car',
            name: 'Car',
            kind: OnboardingCategoryKind.expense,
            iconKey: 'directions_car',
            isSystem: false,
            isFixedExpense: true,
          ),
          OnboardingCategoryDraft(
            id: 'food',
            name: 'Food',
            kind: OnboardingCategoryKind.expense,
            iconKey: 'restaurant',
            isSystem: false,
          ),
        ],
        budgetsMinorByCategory: const {'car': 100, 'food': 50},
        requestId: 'req-test-1',
      );
      final payload = draft.toCommitPayload();
      expect(payload['requestId'], 'req-test-1');
      expect(payload['budgetsMinorByCategory'], {'car': 100, 'food': 50});
      final profile = payload['profile'] as Map<String, dynamic>;
      expect(profile['displayName'], 'Ada');
      expect(profile['mainCurrency'], 'USD');
      final cats = payload['categories'] as List<dynamic>;
      expect((cats.first as Map<String, dynamic>)['isFixedExpense'], true);
    },
  );

  test(
    'onboardingCategoriesForDisplay orders income, fixed-flagged expenses, then others',
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
      const car = OnboardingCategoryDraft(
        id: 'car',
        name: 'Car',
        kind: OnboardingCategoryKind.expense,
        iconKey: 'directions_car',
        isSystem: false,
        isFixedExpense: true,
      );
      final sorted = onboardingCategoriesForDisplay([food, car, salary]);
      expect(sorted.map((c) => c.id).toList(), ['salary', 'car', 'food']);
    },
  );

  test(
    'projected savings uses fixed + variable expense budgets from flags',
    () {
      final draft = OnboardingDraft(
        categories: const [
          OnboardingCategoryDraft(
            id: 'salary',
            name: 'Salary',
            kind: OnboardingCategoryKind.income,
            iconKey: 'work',
            isSystem: false,
          ),
          OnboardingCategoryDraft(
            id: 'car',
            name: 'Car',
            kind: OnboardingCategoryKind.expense,
            iconKey: 'directions_car',
            isSystem: false,
            isFixedExpense: true,
          ),
          OnboardingCategoryDraft(
            id: 'rent',
            name: 'Rent',
            kind: OnboardingCategoryKind.expense,
            iconKey: 'home',
            isSystem: false,
            isFixedExpense: true,
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
          'car': 120000,
          'rent': 80000,
          'food': 100000,
        },
      );

      expect(draft.expectedIncomeMinor, 500000);
      expect(draft.fixedExpensesMinor, 200000);
      expect(draft.variableExpensesMinor, 100000);
      expect(draft.projectedSavingsMinor, 200000);
    },
  );

  test(
    'onboardingFirstExpenseCategoryId returns first expense in display order',
    () {
      const income = OnboardingCategoryDraft(
        id: 'salary',
        name: 'Salary',
        kind: OnboardingCategoryKind.income,
        iconKey: 'work',
        isSystem: false,
      );
      const car = OnboardingCategoryDraft(
        id: 'car',
        name: 'Car',
        kind: OnboardingCategoryKind.expense,
        iconKey: 'directions_car',
        isSystem: false,
        isFixedExpense: true,
      );
      const food = OnboardingCategoryDraft(
        id: 'food',
        name: 'Food',
        kind: OnboardingCategoryKind.expense,
        iconKey: 'restaurant',
        isSystem: false,
      );
      expect(onboardingFirstExpenseCategoryId([food, income, car]), 'car');
    },
  );
}
