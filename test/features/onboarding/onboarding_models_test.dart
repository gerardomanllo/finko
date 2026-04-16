import 'package:flutter_test/flutter_test.dart';
import 'package:finko/features/onboarding/domain/onboarding_models.dart';

void main() {
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
