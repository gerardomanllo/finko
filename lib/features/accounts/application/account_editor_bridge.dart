import '../../../core/data/models/finko_enums.dart';
import '../../onboarding/domain/onboarding_models.dart';

OnboardingAccountType onboardingAccountTypeFromFinko(FinkoAccountType t) {
  return OnboardingAccountType.values.firstWhere((e) => e.name == t.name);
}

FinkoAccountType finkoAccountTypeFromOnboarding(OnboardingAccountType t) {
  return FinkoAccountType.values.firstWhere((e) => e.name == t.name);
}

bool defaultIncludeInNetCashForFinkoType(FinkoAccountType t) {
  return t == FinkoAccountType.checking || t == FinkoAccountType.creditCard;
}
