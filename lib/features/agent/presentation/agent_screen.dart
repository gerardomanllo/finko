import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/launch/launch_screen_preference.dart';
import '../../../l10n/app_localizations.dart';
import '../data/agent_catalog_provider.dart';
import '../data/agent_catalog_snapshot.dart';
import '../data/agent_repository.dart';
import '../domain/agent_draft_resolver.dart';
import '../domain/agent_flow_plan.dart';
import '../domain/agent_message.dart';
import '../domain/agent_outbound.dart';
import '../domain/agent_transaction_flow.dart';
import 'widgets/agent_composer.dart';
import 'widgets/agent_entrance.dart';
import 'widgets/agent_draft_field_editor.dart';
import 'widgets/agent_failed_row.dart';
import 'widgets/agent_live_transaction_card.dart';
import 'widgets/agent_status_row.dart';
import 'widgets/agent_thread_item.dart';

class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  final _scrollController = ScrollController();
  bool _promptChecked = false;
  bool _localThinking = false;
  bool _actionInFlight = false;

  final List<AgentOutboundMessage> _outbound = [];
  final Map<String, Map<AgentFlowFieldKey, String>> _localFlowFields = {};

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

  AgentFlowPlan? _planForUserText(String? text, {String? flowId}) {
    if (text == null || text.trim().isEmpty) return null;
    final catalog = ref.read(agentCatalogProvider);
    final local = flowId != null ? _localFlowFields[flowId] : null;
    final draft = resolveAgentDraft(
      text: text,
      catalog: catalog,
      localOverrides: local,
    );
    if (!draft.hasResolvableIntent) return null;

    return buildAgentFlowPlan(
      draft: draft,
      categories: catalog.finkoCategories,
      accounts: catalog.finkoAccounts,
    );
  }

  AgentLiveTransactionState _enrichState({
    required AgentTransactionFlowSegment flow,
    required AgentFlowPlan? plan,
    required AgentCatalogSnapshot catalog,
  }) {
    final local = _localFlowFields[flow.id] ?? {};
    final draft = resolveAgentDraft(
      text: flow.userMessage.text ?? '',
      catalog: catalog,
      localOverrides: local.isEmpty ? null : local,
    );
    final clientState = draftToLiveState(draft, catalog);

    if (flow.assistantMessages.isEmpty) {
      return clientState;
    }

    var state = buildLiveTransactionState(
      flow.userMessage,
      flow.assistantMessages,
      localFields: local,
    );

    if (state.phase != AgentFlowPhase.confirm &&
        state.phase != AgentFlowPhase.sealed) {
      if (state.amount == null && clientState.amount != null) {
        state = state.copyWith(amount: clientState.amount);
      }
      if (state.memo == null && clientState.memo != null) {
        state = state.copyWith(memo: clientState.memo);
      }
      if (!state.directionKnown && clientState.directionKnown) {
        state = state.copyWith(
          directionIsIncome: clientState.directionIsIncome,
        );
      }
      if (state.category == null && clientState.category != null) {
        state = state.copyWith(category: clientState.category);
      }
      if (state.account == null && clientState.account != null) {
        state = state.copyWith(account: clientState.account);
      }
    }

    final sources = Map<AgentFlowFieldKey, AgentFieldSource>.from(
      plan?.fieldSources ?? draft.sources,
    );
    if (state.phase == AgentFlowPhase.confirm ||
        state.phase == AgentFlowPhase.sealed) {
      return state;
    }

    return state.copyWith(fieldSources: sources);
  }

  AgentTransactionFlowSegment _flowWithEnrichment(
    AgentTransactionFlowSegment flow,
    AgentFlowPlan? plan,
  ) {
    final catalog = ref.read(agentCatalogProvider);
    final state = _enrichState(flow: flow, plan: plan, catalog: catalog);
    return AgentTransactionFlowSegment(
      id: flow.id,
      userMessage: flow.userMessage,
      assistantMessages: flow.assistantMessages,
      state: state,
      activeMessage: flow.activeMessage,
    );
  }

  int _stepIndexForFlow(AgentFlowPlan plan, AgentLiveTransactionState state) {
    return resolveFlowStepIndex(plan: plan, state: state);
  }

  Future<void> _editDraftField({
    required String flowId,
    required AgentFlowPlan? plan,
    required AgentTransactionFlowSegment flow,
    required AgentDraftEditableField field,
  }) async {
    if (_actionInFlight) return;

    final catalog = ref.read(agentCatalogProvider);
    final state = _enrichState(flow: flow, plan: plan, catalog: catalog);

    final updates = await showAgentDraftFieldEditor(
      context: context,
      field: field,
      state: state,
      categories: catalog.finkoCategories,
      accounts: catalog.finkoAccounts,
    );
    if (updates == null || !mounted) return;

    setState(() {
      final fields = _localFlowFields.putIfAbsent(flowId, () => {});
      for (final entry in updates.entries) {
        if (entry.value.isEmpty) {
          fields[entry.key] = agentLocalFieldCleared;
        } else {
          fields[entry.key] = entry.value;
        }
      }
    });
  }

  Future<void> _handleFlowAction({
    required AgentRepository repo,
    required String flowId,
    required AgentFlowPlan plan,
    required AgentLiveTransactionState state,
    required String code,
    required AgentMessage? activeMessage,
  }) async {
    if (_actionInFlight) return;

    final stepKind = plan
        .stepAt(resolveFlowStepIndex(plan: plan, state: state))
        ?.kind;
    final fieldKey =
        fieldKeyForCallback(code) ??
        (stepKind != null ? fieldKeyForStep(stepKind) : null);

    final label =
        labelForPlanCallback(plan, code) ??
        (activeMessage != null
            ? choiceLabelForCallback(activeMessage, code)
            : null);

    if (fieldKey != null && label != null) {
      setState(() {
        final fields = _localFlowFields.putIfAbsent(flowId, () => {});
        fields[fieldKey] = label;
        if (fieldKey == AgentFlowFieldKey.category) {
          final catalog = ref.read(agentCatalogProvider);
          final dir =
              directionFromCategoryLabel(label, catalog.finkoCategories) ??
              plan.directionIsIncome;
          if (dir != null) {
            fields[AgentFlowFieldKey.direction] = dir ? 'IN' : 'OUT';
          }
        }
      });
    }

    setState(() => _actionInFlight = true);
    try {
      await repo.submitAction(code);
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  Future<void> _sendText(AgentRepository repo, String uid, String text) async {
    final clientMessageId = 't_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _outbound.add(
        AgentOutboundMessage(
          clientMessageId: clientMessageId,
          text: text,
          createdAt: DateTime.now(),
        ),
      );
      _localThinking = true;
    });
    _scrollToBottom();
    try {
      await repo.sendText(
        uid: uid,
        text: text,
        clientMessageId: clientMessageId,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final i = _outbound.indexWhere(
          (o) => o.clientMessageId == clientMessageId,
        );
        if (i >= 0) {
          _outbound[i] = _outbound[i].copyWith(sending: false, failed: true);
        }
        _localThinking = false;
      });
    }
  }

  void _syncOutbound(List<AgentMessage> server, bool busy) {
    final acked = server
        .map((m) => m.clientMessageId)
        .whereType<String>()
        .toSet();
    _outbound.removeWhere((o) => acked.contains(o.clientMessageId));
    if (busy || server.any((m) => m.isAssistant && !m.isProcessing)) {
      _localThinking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(agentMessagesStreamProvider);
    final uid = ref.watch(authUidProvider);
    final repo = ref.watch(agentRepositoryProvider);
    ref.watch(agentCatalogProvider);

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
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: messagesAsync.when(
                data: (serverMessages) {
                  final processing = serverMessages
                      .where((m) => m.isProcessing)
                      .toList();
                  final busy = processing.isNotEmpty || _actionInFlight;
                  _syncOutbound(serverMessages, busy);

                  final messages = mergeAgentMessagesWithOutbound(
                    server: serverMessages,
                    outbound: _outbound,
                  );
                  _scrollToBottom();

                  final segments = segmentAgentThread(messages);
                  final flowIds = segments
                      .whereType<AgentThreadFlowSegment>()
                      .map((s) => s.flow.id)
                      .toSet();
                  _localFlowFields.removeWhere(
                    (id, _) => !flowIds.contains(id),
                  );

                  final children = <Widget>[];
                  var animIndex = 0;
                  final hasActiveFlow = segments.any(
                    (s) =>
                        s is AgentThreadFlowSegment && !s.flow.state.isSealed,
                  );

                  for (final segment in segments) {
                    switch (segment) {
                      case AgentThreadUserSegment(:final message):
                        children.add(
                          AgentEntrance(
                            index: animIndex++,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: AgentThreadItem(
                                message: message,
                                actionsEnabled: !busy,
                                onAction: repo.submitAction,
                                sending: isOutboundPending(
                                  message: message,
                                  outbound: _outbound,
                                ),
                                animateUser: true,
                              ),
                            ),
                          ),
                        );
                      case AgentThreadFlowSegment(:final flow):
                        final plan = _planForUserText(
                          flow.userMessage.text,
                          flowId: flow.id,
                        );
                        final enriched = _flowWithEnrichment(flow, plan);
                        final stepIndex = plan != null
                            ? _stepIndexForFlow(plan, enriched.state)
                            : 0;
                        children.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: AgentLiveTransactionCard(
                              flow: enriched,
                              plan: plan,
                              stepIndex: stepIndex,
                              actionsEnabled: !busy,
                              pending: false,
                              onEditField: (field) => _editDraftField(
                                flowId: flow.id,
                                plan: plan,
                                flow: enriched,
                                field: field,
                              ),
                              onAction: plan != null
                                  ? (code) => _handleFlowAction(
                                      repo: repo,
                                      flowId: flow.id,
                                      plan: plan,
                                      state: enriched.state,
                                      code: code,
                                      activeMessage: enriched.activeMessage,
                                    )
                                  : repo.submitAction,
                            ),
                          ),
                        );
                      case AgentThreadAssistantSegment(:final message):
                        if (message.isFailed) {
                          children.add(
                            AgentFailedRow(
                              errorLabelKey: message.errorLabelKey,
                              onDismiss: () => repo.dismissMessage(message.id),
                            ),
                          );
                        } else {
                          children.add(
                            AgentEntrance(
                              index: animIndex++,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: AgentThreadItem(
                                  message: message,
                                  actionsEnabled: !busy,
                                  onAction: repo.submitAction,
                                ),
                              ),
                            ),
                          );
                        }
                    }
                  }

                  final showPendingCard =
                      (_localThinking || _outbound.any((o) => o.sending)) &&
                      !hasActiveFlow;
                  if (showPendingCard) {
                    final lastOutbound = _outbound.isNotEmpty
                        ? _outbound.last
                        : null;
                    final pendingUser = lastOutbound != null
                        ? AgentMessage(
                            id: 'local-${lastOutbound.clientMessageId}',
                            role: 'user',
                            kind: 'text',
                            text: lastOutbound.text,
                            clientMessageId: lastOutbound.clientMessageId,
                            createdAt: lastOutbound.createdAt,
                          )
                        : null;

                    if (pendingUser != null &&
                        !segments.any(
                          (s) =>
                              s is AgentThreadUserSegment &&
                              s.message.clientMessageId ==
                                  pendingUser.clientMessageId,
                        )) {
                      children.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: AgentThreadItem(
                            message: pendingUser,
                            actionsEnabled: false,
                            onAction: (_) {},
                            sending: true,
                            animateUser: true,
                          ),
                        ),
                      );
                    }

                    final pendingFlow = _pendingFlowFromText(
                      lastOutbound?.text ?? '',
                      pendingUser,
                    );
                    if (pendingFlow != null) {
                      final plan = _planForUserText(
                        lastOutbound?.text,
                        flowId: pendingFlow.id,
                      );
                      final enriched = plan != null
                          ? _flowWithEnrichment(pendingFlow, plan)
                          : pendingFlow;
                      children.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: AgentLiveTransactionCard(
                            flow: enriched,
                            plan: plan,
                            stepIndex: plan != null
                                ? _stepIndexForFlow(plan, enriched.state)
                                : 0,
                            actionsEnabled: !_actionInFlight && plan != null,
                            pending: false,
                            onEditField: plan != null
                                ? (field) => _editDraftField(
                                    flowId: pendingFlow.id,
                                    plan: plan,
                                    flow: enriched,
                                    field: field,
                                  )
                                : null,
                            onAction: plan != null
                                ? (code) => _handleFlowAction(
                                    repo: repo,
                                    flowId: pendingFlow.id,
                                    plan: plan,
                                    state: enriched.state,
                                    code: code,
                                    activeMessage: null,
                                  )
                                : (_) {},
                          ),
                        ),
                      );
                    }
                  }

                  if (_localThinking || busy) {
                    children.add(
                      AgentStatusRow(
                        statusLabelKey: processing.isNotEmpty
                            ? processing.first.statusLabelKey
                            : 'agentStatus.receiving',
                      ),
                    );
                  }

                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    children: children,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ),
          if (uid != null)
            AgentComposer(
              busy: _actionInFlight,
              onSendText: (text) => _sendText(repo, uid, text),
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

  AgentTransactionFlowSegment? _pendingFlowFromText(
    String text,
    AgentMessage? userMessage,
  ) {
    if (userMessage == null) return null;
    final flowId = 'pending-${userMessage.id}';
    final plan = _planForUserText(text, flowId: flowId);
    if (plan == null) return null;

    final catalog = ref.read(agentCatalogProvider);
    final state = _enrichState(
      flow: AgentTransactionFlowSegment(
        id: flowId,
        userMessage: userMessage,
        assistantMessages: const [],
        state: const AgentLiveTransactionState(),
        activeMessage: null,
      ),
      plan: plan,
      catalog: catalog,
    );

    return AgentTransactionFlowSegment(
      id: flowId,
      userMessage: userMessage,
      assistantMessages: const [],
      state: state,
      activeMessage: null,
    );
  }
}
