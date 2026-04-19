import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/models/user_profile.dart';
import '../../../core/ui/finko_modal_sheet_extent.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet: linked channel identity + verified date + disconnect.
Future<void> showSettingsMessagingConnectedSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required String channel,
  required UserProfile profile,
  required VoidCallback onDisconnect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ConnectedMessagingSheet(
      l10n: l10n,
      channel: channel,
      profile: profile,
      onDisconnect: onDisconnect,
    ),
  );
}

class _ConnectedMessagingSheet extends StatelessWidget {
  const _ConnectedMessagingSheet({
    required this.l10n,
    required this.channel,
    required this.profile,
    required this.onDisconnect,
  });

  final AppLocalizations l10n;
  final String channel;
  final UserProfile profile;
  final VoidCallback onDisconnect;

  bool get _isWa => channel == 'whatsapp';

  @override
  Widget build(BuildContext context) {
    final brand = _isWa ? const Color(0xFF25D366) : const Color(0xFF0088CC);
    final title = _isWa
        ? l10n.settingsMessagingWhatsApp
        : l10n.settingsMessagingTelegram;
    final localeTag = Localizations.localeOf(context).toString();

    final List<Widget> details;
    if (_isWa) {
      final w = profile.integrations.whatsapp!;
      final verified = w.verifiedAt != null
          ? DateFormat.yMMMd(localeTag).format(w.verifiedAt!.toLocal())
          : '—';
      details = [
        Text(
          l10n.settingsMessagingConnectedWhatsAppDetail(w.phoneE164),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsMessagingVerifiedOn(verified),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ];
    } else {
      final t = profile.integrations.telegram!;
      final handle = t.username.startsWith('@') ? t.username : '@${t.username}';
      final verified = t.verifiedAt != null
          ? DateFormat.yMMMd(localeTag).format(t.verifiedAt!.toLocal())
          : '—';
      details = [
        Text(
          l10n.settingsMessagingConnectedTelegramDetail(handle),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.settingsMessagingVerifiedOn(verified),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = finkoModalSheetMaxHeight(
          context,
          layoutMaxHeight: constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : null,
        );
        return SizedBox(
          height: maxH,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
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
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ...details,
                        const SizedBox(height: 20),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDisconnect();
                          },
                          child: Text(l10n.settingsMessagingDisconnect),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
