import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/firestore_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/messaging_otp_request_result.dart';

enum _TelegramLinkMode { phone, username }

enum _TelegramFlowPhase { form, preparing, awaitingBot, linkedSuccess, failed }

/// Dial code → short label (EN; labels are for debug/dropdown only).
const List<(String code, String label)> _kDialCodes = [
  ('+52', 'Mexico +52'),
  ('+1', 'US/CA +1'),
  ('+34', 'Spain +34'),
  ('+44', 'UK +44'),
  ('+33', 'France +33'),
  ('+49', 'Germany +49'),
  ('+54', 'Argentina +54'),
  ('+56', 'Chile +56'),
  ('+57', 'Colombia +57'),
  ('+51', 'Peru +51'),
  ('+598', 'Uruguay +598'),
  ('+351', 'Portugal +351'),
  ('+39', 'Italy +39'),
  ('+55', 'Brazil +55'),
];

/// Telegram-only bottom sheet: phone vs username, magic link + Firestore listener (no OTP).
class TelegramChannelLinkSheet extends StatefulWidget {
  const TelegramChannelLinkSheet({
    super.key,
    required this.uid,
    required this.l10n,
    required this.firestore,
    required this.initialIdentity,
    required this.onRequestOtp,
    required this.onLinked,
  });

  final String uid;
  final AppLocalizations l10n;
  final FirebaseFirestore firestore;
  final String initialIdentity;
  final Future<MessagingOtpRequestResult> Function(String identity)
  onRequestOtp;
  final void Function(String identity) onLinked;

  @override
  State<TelegramChannelLinkSheet> createState() =>
      _TelegramChannelLinkSheetState();
}

class _TelegramChannelLinkSheetState extends State<TelegramChannelLinkSheet> {
  static final RegExp _e164ish = RegExp(r'^\+\d{8,}$');

  _TelegramLinkMode _mode = _TelegramLinkMode.username;
  _TelegramFlowPhase _phase = _TelegramFlowPhase.form;

  String _dialCode = '+52';
  final TextEditingController _phoneDigits = TextEditingController();
  final TextEditingController _username = TextEditingController();

  String _statusHeadline = '';
  String _failureStep = '';
  String _failureDetail = '';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _linkSub;
  Timer? _linkTimeout;

  Uri? _deepLink;
  String _linkIdentity = '';

  @override
  void initState() {
    super.initState();
    _applyInitialIdentity(widget.initialIdentity);
  }

  void _applyInitialIdentity(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    if (_e164ish.hasMatch(t)) {
      setState(() {
        _mode = _TelegramLinkMode.phone;
      });
      final codes = _kDialCodes.map((e) => e.$1).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final c in codes) {
        if (t.startsWith(c)) {
          _dialCode = c;
          _phoneDigits.text = t
              .substring(c.length)
              .replaceAll(RegExp(r'\D'), '');
          return;
        }
      }
      _phoneDigits.text = t.replaceAll(RegExp(r'[^\d]'), '');
      return;
    }
    setState(() {
      _mode = _TelegramLinkMode.username;
    });
    _username.text = t.startsWith('@') ? t : '@$t';
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _linkTimeout?.cancel();
    _phoneDigits.dispose();
    _username.dispose();
    super.dispose();
  }

  void _trace(String message) {
    if (kDebugMode) {
      debugPrint('[TelegramLink UX] $message');
    }
  }

  String _composeIdentity() {
    if (_mode == _TelegramLinkMode.phone) {
      final digits = _phoneDigits.text.replaceAll(RegExp(r'\D'), '');
      return '$_dialCode$digits';
    }
    return _username.text.trim();
  }

  bool _validateForm(BuildContext context) {
    if (_mode == _TelegramLinkMode.phone) {
      final digits = _phoneDigits.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.messagingTelegramErrPhoneTooShort),
          ),
        );
        return false;
      }
      final full = '$_dialCode$digits';
      if (!_e164ish.hasMatch(full)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.messagingTelegramErrPhoneFormat)),
        );
        return false;
      }
    } else {
      final u = _username.text.trim().replaceFirst('@', '');
      if (u.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.messagingTelegramErrUsernameTooShort),
          ),
        );
        return false;
      }
    }
    return true;
  }

  void _fail(String step, String detail) {
    _linkSub?.cancel();
    _linkTimeout?.cancel();
    _trace('FAIL at "$step"${detail.isEmpty ? '' : ': $detail'}');
    setState(() {
      _phase = _TelegramFlowPhase.failed;
      _failureStep = step;
      _failureDetail = detail;
    });
  }

  Future<void> _onFormNext() async {
    if (!mounted) return;
    if (!_validateForm(context)) return;

    setState(() {
      _phase = _TelegramFlowPhase.preparing;
      _statusHeadline = widget.l10n.messagingTelegramStatusRegistering;
    });
    _linkIdentity = _composeIdentity();
    _trace('Next tapped. mode=$_mode identity=$_linkIdentity');

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _statusHeadline = widget.l10n.messagingTelegramStatusPreparingTelegram;
    });
    _trace(
      'Calling Cloud Function requestMessagingOtp(channel=telegram, identity=…)',
    );

    try {
      final r = await widget.onRequestOtp(_linkIdentity);
      if (!mounted) return;

      final code = r.debugOtpCode;
      if (code != null && code.isNotEmpty) {
        _trace('Callable returned debugOtpCode (dev project): $code');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.messagingOtpDevCodeSnack(code))),
        );
      }

      _trace(
        'Callable result: ok=${r.needsBotStart == false || r.deepLink != null}, '
        'needsBotStart=${r.needsBotStart}, deepLink=${r.deepLink}',
      );

      if (r.needsBotStart) {
        if (r.deepLink == null) {
          _fail(
            widget.l10n.messagingTelegramErrStepServer,
            widget.l10n.messagingTelegramErrNoDeepLink,
          );
          return;
        }
        setState(() {
          _deepLink = r.deepLink;
          _phase = _TelegramFlowPhase.awaitingBot;
          _statusHeadline = widget.l10n.messagingTelegramStatusWaitingForBot;
        });
        _trace(
          'Listening to ${FirestorePaths.telegramLinkStateDoc(widget.uid)}',
        );
        _startLinkListener();
        _linkTimeout = Timer(const Duration(minutes: 5), () {
          if (!mounted) return;
          if (_phase == _TelegramFlowPhase.awaitingBot) {
            _fail(
              widget.l10n.messagingTelegramErrStepTimeout,
              widget.l10n.messagingTelegramTimeoutBody,
            );
          }
        });
        return;
      }

      if (r.messagingReady) {
        _trace('messagingReady=true — Telegram already connected on server.');
        setState(() {
          _phase = _TelegramFlowPhase.linkedSuccess;
          _statusHeadline = widget.l10n.messagingTelegramStatusLinkDetected;
        });
        return;
      }

      _fail(
        widget.l10n.messagingTelegramErrStepServer,
        widget.l10n.messagingTelegramErrUnexpectedResponse,
      );
    } on FirebaseFunctionsException catch (e) {
      _fail(widget.l10n.messagingTelegramErrStepCallable, e.message ?? e.code);
    } catch (e, st) {
      _trace('Unexpected error: $e\n$st');
      _fail(widget.l10n.messagingTelegramErrStepUnknown, '$e');
    }
  }

  void _startLinkListener() {
    _linkSub?.cancel();
    final ref = widget.firestore.doc(
      FirestorePaths.telegramLinkStateDoc(widget.uid),
    );
    _linkSub = ref.snapshots().listen(
      (snap) {
        _trace(
          'Snapshot received: exists=${snap.exists} '
          'keys=${snap.data()?.keys.join(",") ?? "—"}',
        );
        if (!snap.exists) return;
        final d = snap.data();
        if (d == null) return;
        final raw = d['chatId'];
        final chatId = raw == null ? '' : raw.toString().trim();
        if (chatId.isEmpty) return;
        _trace('Non-empty chatId detected — treating link as success.');
        _linkTimeout?.cancel();
        if (!mounted) return;
        setState(() {
          _phase = _TelegramFlowPhase.linkedSuccess;
          _statusHeadline = widget.l10n.messagingTelegramStatusLinkDetected;
        });
      },
      onError: (Object e, StackTrace st) {
        _trace('Listen error: $e\n$st');
        _fail(widget.l10n.messagingTelegramErrStepFirestore, '$e');
      },
    );
  }

  Future<void> _openTelegram() async {
    final uri = _deepLink;
    if (uri == null) return;
    for (final candidate in _telegramLaunchCandidates(uri)) {
      _trace('Launching external app for $candidate');
      final ok = await launchUrl(
        candidate,
        mode: LaunchMode.externalApplication,
      );
      _trace('launchUrl completed: ok=$ok url=$candidate');
      if (ok) {
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.l10n.messagingTelegramErrLaunchTelegram)),
    );
  }

  /// Prefer `tg://resolve?domain=…&start=…` (matches [Telegram bot links](https://core.telegram.org/api/links))
  /// before `https://t.me/…?start=…` so the payload survives app handoff. Callable returns `tg://…` with the same `start`
  /// as the webhook expects (`/start link_<token>` after the user taps **Start**).
  List<Uri> _telegramLaunchCandidates(Uri u) {
    final hostLower = u.host.toLowerCase();
    final schemeLower = u.scheme.toLowerCase();
    final isTme = hostLower == 't.me' || hostLower == 'telegram.me';
    final isTgResolve = schemeLower == 'tg' && hostLower == 'resolve';

    String? domain;
    String? start;

    if (isTgResolve) {
      domain = u.queryParameters['domain'];
      start = u.queryParameters['start'];
    } else if (isTme && (schemeLower == 'https' || schemeLower == 'http')) {
      final segments = u.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        domain = segments.first;
        start = u.queryParameters['start'];
      }
    }

    if (domain != null &&
        domain.isNotEmpty &&
        start != null &&
        start.isNotEmpty) {
      return <Uri>[
        Uri(
          scheme: 'tg',
          host: 'resolve',
          queryParameters: <String, String>{'domain': domain, 'start': start},
        ),
        Uri(
          scheme: 'https',
          host: 't.me',
          pathSegments: <String>[domain],
          queryParameters: <String, String>{'start': start},
        ),
      ];
    }

    return <Uri>[u];
  }

  void _finishTelegramLink() {
    _linkSub?.cancel();
    _linkTimeout?.cancel();
    widget.onLinked(_linkIdentity);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF0088CC);
    final l10n = widget.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
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
            l10n.settingsMessagingTelegram,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        switch (_phase) {
                          _TelegramFlowPhase.form => _buildForm(
                            context,
                            l10n,
                            brand,
                          ),
                          _TelegramFlowPhase.preparing => _buildPreparing(
                            context,
                            l10n,
                          ),
                          _TelegramFlowPhase.awaitingBot => _buildAwaitingBot(
                            context,
                            l10n,
                            brand,
                          ),
                          _TelegramFlowPhase.linkedSuccess =>
                            _buildLinkedSuccess(context, l10n, brand),
                          _TelegramFlowPhase.failed => _buildFailed(
                            context,
                            l10n,
                          ),
                        },
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n, Color brand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.messagingTelegramIntro,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.messagingTelegramLinkMethodLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<_TelegramLinkMode>(
          segments: [
            ButtonSegment(
              value: _TelegramLinkMode.phone,
              label: Text(l10n.messagingTelegramLinkMethodPhone),
              icon: const Icon(Icons.phone_android_outlined, size: 18),
            ),
            ButtonSegment(
              value: _TelegramLinkMode.username,
              label: Text(l10n.messagingTelegramLinkMethodUsername),
              icon: const Icon(Icons.alternate_email, size: 18),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (Set<_TelegramLinkMode> s) {
            setState(() {
              _mode = s.first;
            });
            _trace('Toggle: mode=$_mode');
          },
        ),
        const SizedBox(height: 16),
        if (_mode == _TelegramLinkMode.phone) ...[
          Text(
            l10n.messagingTelegramCountryCodeLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _dialCode,
                items: _kDialCodes
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.$1,
                        child: Text(e.$2, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _dialCode = v);
                  _trace('Dial code set to $v');
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.messagingTelegramPhoneLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneDigits,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.messagingTelegramPhoneHint,
            ),
          ),
        ] else ...[
          Text(
            l10n.messagingTelegramUsernameLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _username,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.onboardingMessagingTelegramHint,
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
          ),
          onPressed: _onFormNext,
          child: Text(l10n.messagingTelegramNext),
        ),
      ],
    );
  }

  Widget _buildPreparing(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          _statusHeadline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.messagingTelegramPreparingHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAwaitingBot(
    BuildContext context,
    AppLocalizations l10n,
    Color brand,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Icon(
          Icons.sync,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          _statusHeadline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.messagingTelegramAwaitingBotBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
          ),
          onPressed: _deepLink == null ? null : _openTelegram,
          icon: const Icon(Icons.telegram),
          label: Text(l10n.messagingTelegramOpenBot),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.messagingTelegramListeningFirestore,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedSuccess(
    BuildContext context,
    AppLocalizations l10n,
    Color brand,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Icon(
          Icons.check_circle,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.messagingTelegramLinkedTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.messagingTelegramLinkedBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
          ),
          onPressed: _finishTelegramLink,
          child: Text(l10n.messagingTelegramDone),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.messagingTelegramClose),
        ),
      ],
    );
  }

  Widget _buildFailed(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.messagingTelegramLinkFailedTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _failureStep,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (_failureDetail.isNotEmpty) ...[
          const SizedBox(height: 8),
          SelectableText(
            _failureDetail,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.tonal(
          onPressed: () {
            _linkSub?.cancel();
            _linkTimeout?.cancel();
            setState(() {
              _phase = _TelegramFlowPhase.form;
              _failureStep = '';
              _failureDetail = '';
              _deepLink = null;
            });
            _trace('User tapped Retry — back to form.');
          },
          child: Text(l10n.messagingTelegramRetry),
        ),
      ],
    );
  }
}
