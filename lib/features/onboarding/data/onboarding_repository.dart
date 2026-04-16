import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_functions_provider.dart';
import '../domain/onboarding_models.dart';

class OnboardingRepository {
  OnboardingRepository({required FirebaseFunctions functions})
    : _functions = functions;

  final FirebaseFunctions _functions;

  Future<void> commitOnboarding(OnboardingDraft draft) async {
    final callable = _functions.httpsCallable('commitOnboarding');
    await callable.call<Map<String, dynamic>>(draft.toCommitPayload());
  }

  Future<void> requestMessagingOtp({
    required String channel,
    required String identity,
  }) async {
    final callable = _functions.httpsCallable('requestMessagingOtp');
    await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'channel': channel,
      'identity': identity.trim(),
    });
  }

  Future<void> verifyMessagingOtp({
    required String channel,
    required String identity,
    required String otpCode,
  }) async {
    final callable = _functions.httpsCallable('verifyMessagingOtp');
    await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'channel': channel,
      'identity': identity.trim(),
      'otpCode': otpCode.trim(),
    });
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) =>
      OnboardingRepository(functions: ref.watch(firebaseFunctionsProvider)),
);
