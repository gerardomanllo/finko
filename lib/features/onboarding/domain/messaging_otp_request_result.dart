/// Response from [requestMessagingOtp] Cloud Function.
class MessagingOtpRequestResult {
  const MessagingOtpRequestResult({
    this.needsBotStart = false,
    this.deepLink,
    this.debugOtpCode,
    this.messagingReady = false,
  });

  final bool needsBotStart;
  final Uri? deepLink;
  final String? debugOtpCode;

  /// Telegram: profile already has [integrations.telegram] (magic link completed).
  final bool messagingReady;

  static MessagingOtpRequestResult fromCallableData(Map<Object?, Object?> raw) {
    final data = <String, Object?>{
      for (final e in raw.entries) e.key.toString(): e.value,
    };
    final needs = data['needsBotStart'] == true;
    final link = data['deepLink'] as String?;
    return MessagingOtpRequestResult(
      needsBotStart: needs,
      deepLink: link != null && link.isNotEmpty ? Uri.tryParse(link) : null,
      debugOtpCode: data['debugOtpCode'] as String?,
      messagingReady: data['messagingReady'] == true,
    );
  }
}
