import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_functions_provider.dart';
import '../domain/messaging_otp_request_result.dart';
import '../domain/onboarding_models.dart';

class OnboardingRepository {
  OnboardingRepository({required FirebaseFunctions functions})
    : _functions = functions;

  final FirebaseFunctions _functions;

  Future<void> commitOnboarding(OnboardingDraft draft) async {
    final callable = _functions.httpsCallable('commitOnboarding');
    await callable.call<Map<String, dynamic>>(draft.toCommitPayload());
  }

  Future<MessagingOtpRequestResult> requestMessagingOtp({
    required String channel,
    required String identity,
  }) async {
    final callable = _functions.httpsCallable('requestMessagingOtp');
    final res = await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'channel': channel,
      'identity': identity.trim(),
    });
    return MessagingOtpRequestResult.fromCallableData(res.data);
  }

  Future<void> disconnectMessagingIntegration({required String channel}) async {
    final callable = _functions.httpsCallable('disconnectMessagingIntegration');
    await callable.call<Map<String, dynamic>>(<String, dynamic>{
      'channel': channel,
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
