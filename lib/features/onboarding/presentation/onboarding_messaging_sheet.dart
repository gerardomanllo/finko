import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/finko_modal_sheet_extent.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/messaging_otp_request_result.dart';
import 'telegram_channel_link_sheet.dart';

/// WhatsApp (green) or Telegram (blue) — connect flow in a bottom sheet.
///
/// **WhatsApp:** [onVerify] is required (OTP). **Telegram:** magic link only — pass
/// [onTelegramLinked] when the profile should refresh or onboarding state should update;
/// [onVerify] is ignored.
Future<void> showOnboardingMessagingChannelSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required String channel,
  required String initialIdentity,
  required String firebaseUid,
  required FirebaseFirestore firestore,
  required Future<MessagingOtpRequestResult> Function(String identity)
  onRequestOtp,
  Future<void> Function(String identity, String otp)? onVerify,
  void Function(String identity)? onTelegramLinked,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxH = finkoModalSheetMaxHeight(
            context,
            layoutMaxHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
          );
          if (channel == 'telegram') {
            return SizedBox(
              height: maxH,
              child: TelegramChannelLinkSheet(
                uid: firebaseUid,
                l10n: l10n,
                firestore: firestore,
                initialIdentity: initialIdentity,
                onRequestOtp: onRequestOtp,
                onLinked: onTelegramLinked ?? (_) {},
              ),
            );
          }
          final whatsappVerify = onVerify;
          if (whatsappVerify == null) {
            throw StateError('onVerify is required for WhatsApp');
          }
          return SizedBox(
            height: maxH,
            child: _WhatsAppMessagingChannelSheet(
              l10n: l10n,
              initialIdentity: initialIdentity,
              onRequestOtp: onRequestOtp,
              onVerify: whatsappVerify,
            ),
          );
        },
      );
    },
  );
}

class _WhatsAppMessagingChannelSheet extends StatefulWidget {
  const _WhatsAppMessagingChannelSheet({
    required this.l10n,
    required this.initialIdentity,
    required this.onRequestOtp,
    required this.onVerify,
  });

  final AppLocalizations l10n;
  final String initialIdentity;
  final Future<MessagingOtpRequestResult> Function(String identity)
  onRequestOtp;
  final Future<void> Function(String identity, String otp) onVerify;

  @override
  State<_WhatsAppMessagingChannelSheet> createState() =>
      _WhatsAppMessagingChannelSheetState();
}

class _WhatsAppMessagingChannelSheetState
    extends State<_WhatsAppMessagingChannelSheet> {
  late final TextEditingController _identity;
  late final TextEditingController _otp;
  bool _busy = false;

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

  Future<void> _onRequestOtpPressed() async {
    setState(() => _busy = true);
    try {
      final r = await widget.onRequestOtp(_identity.text.trim());
      if (!mounted) return;

      final code = r.debugOtpCode;
      if (code != null && code.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.messagingOtpDevCodeSnack(code))),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Request failed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    const brand = Color(0xFF25D366);

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
            Text('WhatsApp', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _identity,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'WhatsApp',
                hintText: l10n.onboardingMessagingWhatsAppHint,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: brand,
                foregroundColor: Colors.white,
              ),
              onPressed: _busy ? null : _onRequestOtpPressed,
              child: Text(l10n.onboardingRequestOtpWhatsApp),
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
                      } on FirebaseFunctionsException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message ?? 'Verification failed'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(l10n.onboardingVerifyWhatsApp),
            ),
          ],
        ),
      ),
    );
  }
}
