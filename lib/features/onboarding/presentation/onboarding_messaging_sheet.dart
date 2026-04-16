import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// WhatsApp (green) or Telegram (blue) — OTP connect flow in a bottom sheet.
Future<void> showOnboardingMessagingChannelSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required String channel,
  required String initialIdentity,
  required Future<void> Function(String identity) onRequestOtp,
  required Future<void> Function(String identity, String otp) onVerify,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _MessagingChannelSheet(
      l10n: l10n,
      channel: channel,
      initialIdentity: initialIdentity,
      onRequestOtp: onRequestOtp,
      onVerify: onVerify,
    ),
  );
}

class _MessagingChannelSheet extends StatefulWidget {
  const _MessagingChannelSheet({
    required this.l10n,
    required this.channel,
    required this.initialIdentity,
    required this.onRequestOtp,
    required this.onVerify,
  });

  final AppLocalizations l10n;
  final String channel;
  final String initialIdentity;
  final Future<void> Function(String identity) onRequestOtp;
  final Future<void> Function(String identity, String otp) onVerify;

  @override
  State<_MessagingChannelSheet> createState() => _MessagingChannelSheetState();
}

class _MessagingChannelSheetState extends State<_MessagingChannelSheet> {
  late final TextEditingController _identity;
  late final TextEditingController _otp;
  bool _busy = false;

  bool get _isWa => widget.channel == 'whatsapp';

  @override
  void initState() {
    super.initState();
    _identity = TextEditingController(text: widget.initialIdentity);
    _otp = TextEditingController();
  }

  @override
  void dispose() {
    _identity.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final brand = _isWa ? const Color(0xFF25D366) : const Color(0xFF0088CC);
    final title = _isWa ? 'WhatsApp' : 'Telegram';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _identity,
              keyboardType: _isWa ? TextInputType.phone : TextInputType.text,
              decoration: InputDecoration(
                labelText: title,
                hintText: _isWa
                    ? l10n.onboardingMessagingWhatsAppHint
                    : l10n.onboardingMessagingTelegramHint,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: Colors.white,
              ),
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await widget.onRequestOtp(_identity.text.trim());
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(
                _isWa
                    ? l10n.onboardingRequestOtpWhatsApp
                    : l10n.onboardingRequestOtpTelegram,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otp,
              decoration: InputDecoration(labelText: l10n.onboardingOtpCode),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await widget.onVerify(
                          _identity.text.trim(),
                          _otp.text.trim(),
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(
                _isWa
                    ? l10n.onboardingVerifyWhatsApp
                    : l10n.onboardingVerifyTelegram,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
