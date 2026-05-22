import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/launch/launch_screen_preference.dart';
import '../../../l10n/app_localizations.dart';
import '../data/agent_repository.dart';
import 'widgets/agent_composer.dart';
import 'widgets/agent_failed_row.dart';
import 'widgets/agent_message_bubble.dart';
import 'widgets/agent_status_row.dart';

class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  final _scrollController = ScrollController();
  bool _promptChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowHomePrompt());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowHomePrompt() async {
    if (_promptChecked || !mounted) return;
    _promptChecked = true;
    if (await readAgentHomePromptSeen()) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.agentHomePromptTitle),
        content: Text(l10n.agentHomePromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.agentHomePromptNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.agentHomePromptYes),
          ),
        ],
      ),
    );
    await markAgentHomePromptSeen();
    if (yes == true && mounted) {
      final uid = ref.read(authUidProvider);
      if (uid != null) {
        await setLaunchScreenPreference(
          firestore: ref.read(firestoreProvider),
          uid: uid,
          screen: LaunchScreen.agent,
        );
        ref.invalidate(launchScreenPreferenceProvider);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(agentMessagesStreamProvider);
    final uid = ref.watch(authUidProvider);
    final repo = ref.watch(agentRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(l10n.agentTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                _scrollToBottom();
                final processing = messages.where((m) => m.isProcessing).toList();
                final busy = processing.isNotEmpty;

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  children: [
                    for (final m in messages)
                      if (m.isProcessing)
                        AgentStatusRow(statusLabelKey: m.statusLabelKey)
                      else if (m.isFailed)
                        AgentFailedRow(
                          errorLabelKey: m.errorLabelKey,
                          onDismiss: () => repo.dismissMessage(m.id),
                        )
                      else if (m.isUser || (m.text?.trim().isNotEmpty ?? false) || m.actions.isNotEmpty)
                        AgentMessageBubble(
                          message: m,
                          actionsEnabled: !busy,
                          onAction: (code) => repo.submitAction(code),
                        ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          if (uid != null)
            AgentComposer(
              busy: messagesAsync.maybeWhen(
                data: (m) => m.any((x) => x.isProcessing),
                orElse: () => false,
              ),
              onSendText: (text) => repo.sendText(
                uid: uid,
                text: text,
                clientMessageId: 't_${DateTime.now().microsecondsSinceEpoch}',
              ),
              onSendImage: (file, {caption}) => repo.sendImageFile(
                uid: uid,
                file: file,
                caption: caption,
                clientMessageId: 'i_${DateTime.now().microsecondsSinceEpoch}',
              ),
              onSendVoice: (file) => repo.sendVoiceFile(
                uid: uid,
                file: file,
                clientMessageId: 'v_${DateTime.now().microsecondsSinceEpoch}',
              ),
            ),
        ],
      ),
    );
  }
}
