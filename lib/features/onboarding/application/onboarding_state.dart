import '../domain/onboarding_models.dart';

class OnboardingState {
  const OnboardingState({
    required this.step,
    required this.draft,
    this.isSubmitting = false,
    this.validationCode,
    this.commitErrorMessage,
  });

  final OnboardingStep step;
  final OnboardingDraft draft;
  final bool isSubmitting;

  /// Machine-readable key mapped to ARB in the onboarding screen.
  final String? validationCode;
  final String? commitErrorMessage;

  double get progress => (step.index + 1) / OnboardingStep.values.length;

  bool get canGoBack => step.index > 0 && step != OnboardingStep.commit;

  OnboardingState copyWith({
    OnboardingStep? step,
    OnboardingDraft? draft,
    bool? isSubmitting,
    String? validationCode,
    String? commitErrorMessage,
    bool clearValidation = false,
    bool clearCommitError = false,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      draft: draft ?? this.draft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      validationCode: clearValidation
          ? null
          : (validationCode ?? this.validationCode),
      commitErrorMessage: clearCommitError
          ? null
          : (commitErrorMessage ?? this.commitErrorMessage),
    );
  }

  static OnboardingState initial() =>
      OnboardingState(step: OnboardingStep.profile, draft: OnboardingDraft());
}
