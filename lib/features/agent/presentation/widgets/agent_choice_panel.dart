import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/agent_message.dart';
import '../../domain/agent_message_presentation.dart';
import 'agent_cancel_link.dart';

class AgentChoicePanel extends StatelessWidget {
  const AgentChoicePanel({
    super.key,
    required this.panel,
    required this.cancelAction,
    required this.onAction,
    this.enabled = true,
    this.showPrompt = true,
  });

  final AgentChoicePanelData panel;
  final AgentActionChip? cancelAction;
  final ValueChanged<String> onAction;
  final bool enabled;
  final bool showPrompt;

  static const int _gridMax = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final useGrid = panel.choices.length <= _gridMax;
    final prompt = _promptForStyle(l10n, panel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPrompt) ...[
          Text(
            prompt,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (useGrid)
          _ChoiceGrid(
            choices: panel.choices,
            icon: _iconForStyle(panel.style),
            enabled: enabled,
            onAction: onAction,
          )
        else
          _ChoiceSelect(
            choices: panel.choices,
            enabled: enabled,
            hint: prompt,
            onAction: onAction,
          ),
        if (cancelAction != null) ...[
          const SizedBox(height: 4),
          AgentCancelLink(
            enabled: enabled,
            onPressed: () => onAction(cancelAction!.callbackCode),
          ),
        ],
      ],
    );
  }

  String _promptForStyle(AppLocalizations l10n, AgentChoicePanelData panel) {
    if (panel.prompt.isNotEmpty &&
        !panel.prompt.toLowerCase().contains('tap a button') &&
        !panel.prompt.toLowerCase().contains('toca un botón')) {
      return panel.prompt;
    }
    return switch (panel.style) {
      AgentChoicePanelStyle.category => l10n.agentPickCategory,
      AgentChoicePanelStyle.account => l10n.agentPickAccount,
      AgentChoicePanelStyle.transfer => l10n.agentPickTransferAccount,
      AgentChoicePanelStyle.recurring => l10n.agentRecurringTitle,
      AgentChoicePanelStyle.generic => panel.prompt,
    };
  }

  IconData _iconForStyle(AgentChoicePanelStyle style) {
    return switch (style) {
      AgentChoicePanelStyle.category => Icons.label_outline_rounded,
      AgentChoicePanelStyle.account => Icons.account_balance_wallet_outlined,
      AgentChoicePanelStyle.transfer => Icons.swap_horiz_rounded,
      AgentChoicePanelStyle.recurring => Icons.event_repeat_rounded,
      AgentChoicePanelStyle.generic => Icons.touch_app_outlined,
    };
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.choices,
    required this.icon,
    required this.enabled,
    required this.onAction,
  });

  final List<AgentActionChip> choices;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: choices.length,
      itemBuilder: (context, index) {
        final choice = choices[index];
        return _GridChoiceTile(
          label: choice.label,
          icon: icon,
          enabled: enabled,
          index: index,
          onTap: () => onAction(choice.callbackCode),
        );
      },
    );
  }
}

class _GridChoiceTile extends StatefulWidget {
  const _GridChoiceTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.index,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final int index;

  @override
  State<_GridChoiceTile> createState() => _GridChoiceTileState();
}

class _GridChoiceTileState extends State<_GridChoiceTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    Future<void>.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.94,
          end: 1,
        ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutBack)),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _pressed = false)
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 90),
            child: Material(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.55,
                  ),
                ),
              ),
              child: InkWell(
                onTap: widget.enabled ? widget.onTap : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.label,
                        style: theme.textTheme.labelMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceSelect extends StatelessWidget {
  const _ChoiceSelect({
    required this.choices,
    required this.enabled,
    required this.hint,
    required this.onAction,
  });

  final List<AgentActionChip> choices;
  final bool enabled;
  final String hint;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            l10n.agentSelectOption,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          value: null,
          onChanged: enabled
              ? (code) {
                  if (code != null) onAction(code);
                }
              : null,
          items: [
            for (final c in choices)
              DropdownMenuItem<String>(
                value: c.callbackCode,
                child: Text(c.label, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }
}
