import 'package:flutter/material.dart';

import '../domain/onboarding_models.dart';

/// Material icon keys the user can assign to an account (independent of account type).
final Map<String, IconData> kOnboardingAccountIconMap = <String, IconData>{
  'account_balance': Icons.account_balance_outlined,
  'savings': Icons.savings_outlined,
  'investment': Icons.trending_up_outlined,
  'credit_card': Icons.credit_card_outlined,
  'loan': Icons.receipt_long_outlined,
  'mortgage': Icons.home_work_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'payments': Icons.payments_outlined,
  'store': Icons.storefront_outlined,
  'currency': Icons.currency_exchange_outlined,
};

String defaultAccountIconKeyForType(OnboardingAccountType type) {
  return switch (type) {
    OnboardingAccountType.checking => 'account_balance',
    OnboardingAccountType.savings => 'savings',
    OnboardingAccountType.investment => 'investment',
    OnboardingAccountType.creditCard => 'credit_card',
    OnboardingAccountType.loan => 'loan',
    OnboardingAccountType.mortgage => 'mortgage',
  };
}

IconData onboardingAccountIconForKey(String key) =>
    kOnboardingAccountIconMap[key] ?? Icons.account_balance_outlined;
