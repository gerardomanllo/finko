import 'package:flutter/material.dart';

import '../../../../core/theme/finko_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/agent_flow_plan.dart';
import '../../domain/agent_message.dart';
import '../../domain/agent_message_presentation.dart';
import '../../domain/agent_transaction_flow.dart';
import 'agent_assistant_line.dart';
import 'agent_choice_panel.dart';
import 'agent_entrance.dart';
import 'agent_draft_field_editor.dart';
import 'agent_transaction_confirm_card.dart';

class AgentLiveTransactionCard extends StatelessWidget {
  const AgentLiveTransactionCard({
    super.key,
    required this.flow,
    required this.onAction,
    this.actionsEnabled = true,
    this.pending = false,
    this.plan,
    this.stepIndex = 0,
    this.onEditField,
  });

  final AgentTransactionFlowSegment flow;
  final ValueChanged<String> onAction;
  final bool actionsEnabled;
  final bool pending;
  final AgentFlowPlan? plan;
  final int stepIndex;
  final ValueChanged<AgentDraftEditableField>? onEditField;

  @override
  Widget build(BuildContext context) {
    final state = flow.state;
    final active = flow.activeMessage;
    final showSkeletons =
        pending || (state.phase == AgentFlowPhase.gathering && !state.isSealed);
    final needsCategorySlot =
        showSkeletons && state.category == null && _planNeedsCategory(plan);
    final needsAccountSlot =
        showSkeletons && state.account == null && _planNeedsAccount(plan);
    final showInteraction = !state.isSealed && (plan != null || active != null);
    final editable = !state.isSealed && onEditField != null;

    void edit(AgentDraftEditableField field) => onEditField?.call(field);

    if (state.isTransfer &&
        state.transfer != null &&
        state.phase == AgentFlowPhase.confirm) {
      final presentation = active != null
          ? resolveAgentPresentation(active)
          : null;
      return AgentEntrance(
        index: 0,
        child: AgentTransferConfirmCard(
          preview: state.transfer!,
          confirmActions: presentation?.confirmActions ?? const [],
          cancelAction: presentation?.cancelAction,
          onAction: onAction,
          enabled: actionsEnabled && !pending,
        ),
      );
    }

    return AgentEntrance(
      index: 0,
      child: _LiveCardShell(
        sealed: state.isSealed,
        cancelled: state.phase == AgentFlowPhase.cancelled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHeader(
              state: state,
              pending: pending,
              editable: editable,
              onEditDirection: editable
                  ? () => edit(AgentDraftEditableField.direction)
                  : null,
            ),
            const SizedBox(height: 14),
            _AnimatedAmount(
              state: state,
              showSkeleton: showSkeletons,
              editable: editable,
              onEdit: editable
                  ? () => edit(AgentDraftEditableField.amount)
                  : null,
            ),
            const SizedBox(height: 6),
            _MemoSlot(
              state: state,
              showSkeleton: showSkeletons,
              editable: editable,
              onEdit: editable
                  ? () => edit(AgentDraftEditableField.memo)
                  : null,
            ),
            const SizedBox(height: 16),
            Divider(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
              height: 1,
            ),
            const SizedBox(height: 14),
            _DetailFieldSlot(
              fieldKey: 'category',
              label: AppLocalizations.of(context).agentFieldCategory,
              icon: Icons.category_outlined,
              value: state.category,
              showSkeleton: needsCategorySlot,
              editable: editable,
              onEdit: editable
                  ? () => edit(AgentDraftEditableField.category)
                  : null,
            ),
            if (needsCategorySlot ||
                needsAccountSlot ||
                state.category != null ||
                state.account != null)
              const SizedBox(height: 12),
            _DetailFieldSlot(
              fieldKey: 'account',
              label: AppLocalizations.of(context).agentFieldAccount,
              icon: Icons.account_balance_wallet_outlined,
              value: state.account,
              showSkeleton: needsAccountSlot,
              editable: editable,
              onEdit: editable
                  ? () => edit(AgentDraftEditableField.account)
                  : null,
            ),
            if (showInteraction) ...[
              const SizedBox(height: 18),
              if (plan != null && plan!.steps.length > 1)
                _StepIndicator(current: stepIndex, total: plan!.steps.length),
              _InteractionZone(
                message: active,
                phase: state.phase,
                plan: plan,
                stepIndex: stepIndex,
                onAction: onAction,
                enabled: actionsEnabled && !pending,
              ),
            ],
            if (state.isSealed) ...[
              const SizedBox(height: 18),
              _SealedBanner(
                text: state.successText ?? '',
                cancelled: state.phase == AgentFlowPhase.cancelled,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _planNeedsCategory(AgentFlowPlan? plan) {
  if (plan == null) return true;
  return plan.steps.any((s) => s.kind == AgentFlowStepKind.pickCategory);
}

bool _planNeedsAccount(AgentFlowPlan? plan) {
  if (plan == null) return true;
  return plan.steps.any((s) => s.kind == AgentFlowStepKind.pickAccount);
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}

class _LiveCardShell extends StatelessWidget {
  const _LiveCardShell({
    required this.child,
    required this.sealed,
    required this.cancelled,
  });

  final Widget child;
  final bool sealed;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = theme.extension<FinkoSemanticColors>()!;
    final borderColor = cancelled
        ? theme.colorScheme.outlineVariant
        : sealed
        ? semantics.income.withValues(alpha: 0.55)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: sealed ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: (sealed ? semantics.income : theme.colorScheme.primary)
                .withValues(alpha: sealed ? 0.12 : 0.06),
            blurRadius: sealed ? 16 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.state,
    required this.pending,
    this.editable = false,
    this.onEditDirection,
  });

  final AgentLiveTransactionState state;
  final bool pending;
  final bool editable;
  final VoidCallback? onEditDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        if (state.directionIsIncome != null)
          _TappableField(
            enabled: editable && onEditDirection != null,
            onTap: onEditDirection,
            borderRadius: BorderRadius.circular(999),
            child: AgentDirectionBadge(isIncome: state.directionIsIncome!),
          )
        else if (editable && onEditDirection != null)
          _TappableField(
            enabled: true,
            onTap: onEditDirection,
            borderRadius: BorderRadius.circular(999),
            child: _UnsetDirectionChip(label: l10n.agentEditDirectionTitle),
          ),
        const Spacer(),
        if (pending)
          _PulsingLabel(text: l10n.agentCardBuilding)
        else if (state.phase == AgentFlowPhase.confirm)
          Text(
            l10n.agentConfirmTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else if (state.isSealed)
          Icon(
            state.phase == AgentFlowPhase.cancelled
                ? Icons.block_rounded
                : Icons.verified_rounded,
            size: 18,
            color: state.phase == AgentFlowPhase.cancelled
                ? theme.colorScheme.onSurfaceVariant
                : theme.extension<FinkoSemanticColors>()!.income,
          ),
      ],
    );
  }
}

class _PulsingLabel extends StatefulWidget {
  const _PulsingLabel({required this.text});

  final String text;

  @override
  State<_PulsingLabel> createState() => _PulsingLabelState();
}

class _PulsingLabelState extends State<_PulsingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Text(
        widget.text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _UnsetDirectionChip extends StatelessWidget {
  const _UnsetDirectionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TappableField extends StatelessWidget {
  const _TappableField({
    required this.enabled,
    required this.onTap,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final bool enabled;
  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!enabled || onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: child,
        ),
      ),
    );
  }
}

class _AnimatedAmount extends StatelessWidget {
  const _AnimatedAmount({
    required this.state,
    required this.showSkeleton,
    this.editable = false,
    this.onEdit,
  });

  final AgentLiveTransactionState state;
  final bool showSkeleton;
  final bool editable;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = theme.extension<FinkoSemanticColors>()!;
    final color = state.directionKnown
        ? (state.isIncome ? semantics.income : semantics.expense)
        : theme.colorScheme.onSurface;
    final hasAmount = state.amount != null && state.amount!.isNotEmpty;

    if (showSkeleton && !hasAmount) {
      return _TappableField(
        enabled: editable,
        onTap: onEdit,
        child: const _AgentShimmerBox(
          height: 40,
          width: 140,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          centered: true,
        ),
      );
    }
    if (!hasAmount) return const SizedBox.shrink();

    return _TappableField(
      enabled: editable,
      onTap: onEdit,
      child: _FadeField(
        fieldKey: 'amount',
        visible: true,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(state.amount),
          tween: Tween(begin: 0.9, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Text(
            state.amount!,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoSlot extends StatelessWidget {
  const _MemoSlot({
    required this.state,
    required this.showSkeleton,
    this.editable = false,
    this.onEdit,
  });

  final AgentLiveTransactionState state;
  final bool showSkeleton;
  final bool editable;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMemo = state.memo != null && state.memo!.isNotEmpty;

    if (showSkeleton && !hasMemo) {
      return _TappableField(
        enabled: editable,
        onTap: onEdit,
        child: const _AgentShimmerBox(
          height: 18,
          width: 160,
          borderRadius: BorderRadius.all(Radius.circular(6)),
          centered: true,
        ),
      );
    }
    if (!hasMemo) return const SizedBox.shrink();

    return _TappableField(
      enabled: editable,
      onTap: onEdit,
      child: _FadeField(
        fieldKey: 'memo',
        visible: true,
        child: Text(
          state.memo!,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DetailFieldSlot extends StatelessWidget {
  const _DetailFieldSlot({
    required this.fieldKey,
    required this.label,
    required this.icon,
    required this.value,
    required this.showSkeleton,
    this.editable = false,
    this.onEdit,
  });

  final String fieldKey;
  final String label;
  final IconData icon;
  final String? value;
  final bool showSkeleton;
  final bool editable;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: showSkeleton && !hasValue
          ? _TappableField(
              enabled: editable,
              onTap: onEdit,
              child: _AgentDetailRowSkeleton(
                key: ValueKey('sk-$fieldKey'),
                label: label,
              ),
            )
          : hasValue
          ? _TappableField(
              enabled: editable,
              onTap: onEdit,
              child: AgentDetailRow(
                key: ValueKey('val-$fieldKey'),
                icon: icon,
                label: label,
                value: value!,
              ),
            )
          : SizedBox.shrink(key: ValueKey('empty-$fieldKey')),
    );
  }
}

/// Shimmer block — used for amount, memo, and detail-row skeletons.
class _AgentShimmerBox extends StatefulWidget {
  const _AgentShimmerBox({
    required this.height,
    required this.width,
    required this.borderRadius,
    this.centered = false,
  });

  final double height;
  final double width;
  final BorderRadius borderRadius;
  final bool centered;

  @override
  State<_AgentShimmerBox> createState() => _AgentShimmerBoxState();
}

class _AgentShimmerBoxState extends State<_AgentShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.55,
    );
    final highlight = theme.colorScheme.primary.withValues(alpha: 0.12);

    final box = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(t * 2, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );

    if (widget.centered) {
      return Center(child: box);
    }
    return box;
  }
}

class _AgentDetailRowSkeleton extends StatelessWidget {
  const _AgentDetailRowSkeleton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const _AgentShimmerBox(
          height: 34,
          width: 34,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.55,
                  ),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              const _AgentShimmerBox(
                height: 14,
                width: 112,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FadeField extends StatelessWidget {
  const _FadeField({
    required this.fieldKey,
    required this.child,
    this.visible = true,
  });

  final String fieldKey;
  final Widget child;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('$fieldKey-${child.runtimeType}'),
        child: child,
      ),
    );
  }
}

class _InteractionZone extends StatelessWidget {
  const _InteractionZone({
    required this.message,
    required this.phase,
    required this.onAction,
    required this.enabled,
    this.plan,
    this.stepIndex = 0,
  });

  final AgentMessage? message;
  final AgentFlowPhase phase;
  final ValueChanged<String> onAction;
  final bool enabled;
  final AgentFlowPlan? plan;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final step = plan?.stepAt(stepIndex);
    final presentation = message != null
        ? resolveAgentPresentation(message!)
        : null;

    Widget child;
    if (step?.kind == AgentFlowStepKind.confirm ||
        phase == AgentFlowPhase.confirm) {
      child = AgentConfirmBar(
        confirmActions: presentation?.confirmActions.isNotEmpty == true
            ? presentation!.confirmActions
            : const [AgentActionChip(id: 'cf', label: '✓', callbackCode: 'cf')],
        cancelAction:
            presentation?.cancelAction ??
            const AgentActionChip(id: 'cx', label: '✗', callbackCode: 'cx'),
        onAction: onAction,
        enabled: enabled && phase == AgentFlowPhase.confirm,
      );
    } else if (presentation?.choicePanel != null) {
      child = AgentChoicePanel(
        panel: presentation!.choicePanel!,
        cancelAction: presentation.cancelAction,
        onAction: onAction,
        enabled: enabled,
      );
    } else if (step?.panel != null) {
      child = AgentChoicePanel(
        panel: step!.panel!,
        cancelAction: const AgentActionChip(
          id: 'cx',
          label: '✗',
          callbackCode: 'cx',
        ),
        onAction: onAction,
        enabled: enabled,
      );
    } else {
      child = const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('step-$stepIndex-${step?.kind.name ?? phase.name}'),
        child: child,
      ),
    );
  }
}

class _SealedBanner extends StatelessWidget {
  const _SealedBanner({required this.text, required this.cancelled});

  final String text;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = theme.extension<FinkoSemanticColors>()!;
    final color = cancelled
        ? theme.colorScheme.onSurfaceVariant
        : semantics.income;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                cancelled ? Icons.block_rounded : Icons.check_circle_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
