import 'package:flutter_test/flutter_test.dart';
import 'package:finko/features/onboarding/domain/onboarding_models.dart';

void main() {
  test(
    'toCommitPayload includes mainCurrency and budgets for commitOnboarding',
    () {
      final draft = OnboardingDraft(
        displayName: '  Ada  ',
        accounts: const [
          OnboardingAccountDraft(
            id: 'a1',
            name: 'Checking',
            type: OnboardingAccountType.checking,
            currency: 'usd',
            colorArgb: 0,
            startingBalanceMinor: 0,
            iconKey: 'account_balance',
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
