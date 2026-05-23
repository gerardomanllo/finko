import 'package:flutter/material.dart';

import '../../../../core/theme/finko_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/agent_message.dart';
import '../../domain/agent_message_presentation.dart';
import 'agent_assistant_line.dart';
import 'agent_cancel_link.dart';

class AgentConfirmBar extends StatelessWidget {
  const AgentConfirmBar({
    super.key,
    required this.confirmActions,
    this.cancelAction,
    required this.onAction,
    this.enabled = true,
  });

  final List<AgentActionChip> confirmActions;
  final AgentActionChip? cancelAction;
  final ValueChanged<String> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (confirmActions.isNotEmpty)
              Expanded(
                child: _AnimatedAgentButton(
                  enabled: enabled,
                  onPressed: () => onAction(confirmActions.first.callbackCode),
                  child: FilledButton.icon(
                    onPressed: enabled
                        ? () => onAction(confirmActions.first.callbackCode)
                        : null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.agentConfirmSave),
                  ),
                ),
              ),
          ],
        ),
        if (cancelAction != null)
          AgentCancelLink(
            enabled: enabled,
            onPressed: () => onAction(cancelAction!.callbackCode),
          ),
      ],
    );
  }
}

class _AnimatedAgentButton extends StatefulWidget {
  const _AnimatedAgentButton({
    required this.child,
    required this.onPressed,
    required this.enabled,
  });

  final Widget child;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<_AnimatedAgentButton> createState() => _AnimatedAgentButtonState();
}

class _AnimatedAgentButtonState extends State<_AnimatedAgentButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class AgentTransactionConfirmCard extends StatelessWidget {
  const AgentTransactionConfirmCard({
    super.key,
    required this.preview,
    required this.confirmActions,
    this.cancelAction,
    required this.onAction,
    this.enabled = true,
  });

  final AgentTransactionPreview preview;
  final List<AgentActionChip> confirmActions;
  final AgentActionChip? cancelAction;
  final ValueChanged<String> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = theme.extension<FinkoSemanticColors>()!;
    final amountColor = preview.isIncome ? semantics.income : semantics.expense;

    return _AgentSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AgentDirectionBadge(isIncome: preview.isIncome),
              const Spacer(),
              Text(
                l10n.agentConfirmTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              preview.amount,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (preview.memo.trim().isNotEmpty && preview.memo != '—') ...[
            const SizedBox(height: 6),
            Text(
              preview.memo,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 18),
          Divider(color: theme.dividerColor.withValues(alpha: 0.7), height: 1),
          const SizedBox(height: 16),
          AgentDetailRow(
            icon: Icons.category_outlined,
            label: l10n.agentFieldCategory,
            value: preview.category,
          ),
          const SizedBox(height: 12),
          AgentDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.agentFieldAccount,
            value: preview.account,
          ),
          const SizedBox(height: 20),
          AgentConfirmBar(
            confirmActions: confirmActions,
            cancelAction: cancelAction,
            onAction: onAction,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

class AgentTransferConfirmCard extends StatelessWidget {
  const AgentTransferConfirmCard({
    super.key,
    required this.preview,
    required this.confirmActions,
    this.cancelAction,
    required this.onAction,
    this.enabled = true,
  });

  final AgentTransferPreview preview;
  final List<AgentActionChip> confirmActions;
  final AgentActionChip? cancelAction;
  final ValueChanged<String> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _AgentSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.agentTransferTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _TransferEndpoint(
            label: l10n.agentTransferFrom,
            account: preview.fromAccount,
            currency: preview.fromCurrency,
            amount: preview.amountOut,
            alignEnd: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.swap_vert_rounded, size: 20),
                ),
              ),
            ),
          ),
          _TransferEndpoint(
            label: l10n.agentTransferTo,
            account: preview.toAccount,
            currency: preview.toCurrency,
            amount: preview.amountIn,
            alignEnd: true,
          ),
          if (preview.memo.trim().isNotEmpty && preview.memo != '—') ...[
            const SizedBox(height: 14),
            AgentDetailRow(
              icon: Icons.notes_rounded,
              label: l10n.agentFieldNote,
              value: preview.memo,
            ),
          ],
          const SizedBox(height: 20),
          AgentConfirmBar(
            confirmActions: confirmActions,
            cancelAction: cancelAction,
            onAction: onAction,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

class _TransferEndpoint extends StatelessWidget {
  const _TransferEndpoint({
    required this.label,
    required this.account,
    required this.currency,
    required this.amount,
    required this.alignEnd,
  });

  final String label;
  final String account;
  final String currency;
  final String amount;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          currency.isEmpty ? account : '$account · $currency',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AgentSurfaceCard extends StatelessWidget {
  const _AgentSurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}
