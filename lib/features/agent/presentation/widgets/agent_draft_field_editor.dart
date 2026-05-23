import 'package:flutter/material.dart';

import '../../../../core/data/models/finko_account.dart';
import '../../../../core/data/models/finko_category.dart';
import '../../../../core/data/models/finko_enums.dart';
import '../../../../core/formatting/amount_input.dart';
import '../../../../core/ui/finko_modal_sheet_extent.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/agent_flow_plan.dart';
import '../../domain/agent_transaction_flow.dart';

enum AgentDraftEditableField { amount, memo, category, account, direction }

Future<Map<AgentFlowFieldKey, String>?> showAgentDraftFieldEditor({
  required BuildContext context,
  required AgentDraftEditableField field,
  required AgentLiveTransactionState state,
  required List<FinkoCategory> categories,
  required List<FinkoAccount> accounts,
}) {
  return showModalBottomSheet<Map<AgentFlowFieldKey, String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _AgentDraftFieldEditorSheet(
      field: field,
      state: state,
      categories: categories,
      accounts: accounts,
    ),
  );
}

class _AgentDraftFieldEditorSheet extends StatefulWidget {
  const _AgentDraftFieldEditorSheet({
    required this.field,
    required this.state,
    required this.categories,
    required this.accounts,
  });

  final AgentDraftEditableField field;
  final AgentLiveTransactionState state;
  final List<FinkoCategory> categories;
  final List<FinkoAccount> accounts;

  @override
  State<_AgentDraftFieldEditorSheet> createState() =>
      _AgentDraftFieldEditorSheetState();
}

class _AgentDraftFieldEditorSheetState extends State<_AgentDraftFieldEditorSheet> {
  late final TextEditingController _textController;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  bool? _directionIsIncome;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _directionIsIncome = widget.state.directionIsIncome ?? false;

    switch (widget.field) {
      case AgentDraftEditableField.amount:
        _textController.text = _rawAmountFromDisplay(widget.state.amount);
      case AgentDraftEditableField.memo:
        _textController.text = widget.state.memo ?? '';
      case AgentDraftEditableField.category:
        _selectedCategoryId = _matchCategoryId(widget.state.category);
      case AgentDraftEditableField.account:
        _selectedAccountId = _matchAccountId(widget.state.account);
      case AgentDraftEditableField.direction:
        break;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _rawAmountFromDisplay(String? display) {
    if (display == null || display.isEmpty) return '';
    return display.replaceAll(RegExp(r'[^\d.,]'), '');
  }

  String? _matchCategoryId(String? label) {
    if (label == null) return null;
    final needle = label.trim().toLowerCase();
    for (final c in widget.categories) {
      final name = c.name.trim().toLowerCase();
      if (name == needle || label.startsWith(c.name)) return c.id;
    }
    return null;
  }

  String? _matchAccountId(String? label) {
    if (label == null) return null;
    for (final a in widget.accounts) {
      if (label.startsWith(a.name) || label.contains(a.name)) return a.id;
    }
    return null;
  }

  String _accountLabel(FinkoAccount account) {
    final name = account.name.length > 20
        ? account.name.substring(0, 20)
        : account.name;
    return '$name (${account.currency})';
  }

  List<FinkoCategory> get _filteredCategories {
    final dir = _directionIsIncome ?? widget.state.directionIsIncome;
    if (dir == null) return widget.categories;
    final kind = dir ? CategoryKind.income : CategoryKind.expense;
    return widget.categories.where((c) => c.kind == kind).toList();
  }

  String _title(AppLocalizations l10n) {
    return switch (widget.field) {
      AgentDraftEditableField.amount => l10n.agentEditAmountTitle,
      AgentDraftEditableField.memo => l10n.agentEditMemoTitle,
      AgentDraftEditableField.category => l10n.agentEditCategoryTitle,
      AgentDraftEditableField.account => l10n.agentEditAccountTitle,
      AgentDraftEditableField.direction => l10n.agentEditDirectionTitle,
    };
  }

  bool get _showsDoneButton {
    return switch (widget.field) {
      AgentDraftEditableField.category ||
      AgentDraftEditableField.account => false,
      _ => true,
    };
  }

  void _pickCategory(String id) {
    final cat = widget.categories.firstWhere((c) => c.id == id);
    Navigator.pop(context, {
      AgentFlowFieldKey.category: cat.name,
      AgentFlowFieldKey.direction:
          cat.kind == CategoryKind.income ? 'IN' : 'OUT',
    });
  }

  void _pickAccount(String id) {
    final account = widget.accounts.firstWhere((a) => a.id == id);
    Navigator.pop(context, {AgentFlowFieldKey.account: _accountLabel(account)});
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final updates = <AgentFlowFieldKey, String>{};

    switch (widget.field) {
      case AgentDraftEditableField.amount:
        final raw = _textController.text.trim();
        if (raw.isEmpty) {
          setState(() => _errorText = l10n.agentEditAmountInvalid);
          return;
        }
        try {
          parseAmountStringToMinorUnits(raw);
        } on FormatException {
          setState(() => _errorText = l10n.agentEditAmountInvalid);
          return;
        }
        updates[AgentFlowFieldKey.amount] = prettyAgentAmount(raw);
      case AgentDraftEditableField.memo:
        final memo = _textController.text.trim();
        if (memo.isEmpty) {
          updates[AgentFlowFieldKey.memo] = '';
        } else {
          updates[AgentFlowFieldKey.memo] = memo;
        }
      case AgentDraftEditableField.category:
        if (_selectedCategoryId == null) return;
        final cat = widget.categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
        );
        updates[AgentFlowFieldKey.category] = cat.name;
        updates[AgentFlowFieldKey.direction] =
            cat.kind == CategoryKind.income ? 'IN' : 'OUT';
      case AgentDraftEditableField.account:
        if (_selectedAccountId == null) return;
        final account = widget.accounts.firstWhere(
          (a) => a.id == _selectedAccountId,
        );
        updates[AgentFlowFieldKey.account] = _accountLabel(account);
      case AgentDraftEditableField.direction:
        final dir = _directionIsIncome;
        if (dir == null) return;
        updates[AgentFlowFieldKey.direction] = dir ? 'IN' : 'OUT';
        final currentCategory = widget.state.category;
        if (currentCategory != null) {
          final catDir = directionFromCategoryLabel(
            currentCategory,
            widget.categories,
          );
          if (catDir != null && catDir != dir) {
            updates[AgentFlowFieldKey.category] = '';
          }
        }
    }

    Navigator.pop(context, updates);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = finkoModalSheetMaxHeight(
          context,
          layoutMaxHeight: constraints.maxHeight,
        );

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_title(l10n), style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Flexible(child: _buildBody(context, l10n, theme)),
                if (_showsDoneButton) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(l10n.agentEditDone),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.agentCancel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return switch (widget.field) {
      AgentDraftEditableField.amount => TextField(
        controller: _textController,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [AmountTextInputFormatter()],
        decoration: InputDecoration(
          labelText: l10n.agentFieldAmount,
          prefixText: '\$ ',
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
      ),
      AgentDraftEditableField.memo => TextField(
        controller: _textController,
        autofocus: true,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.agentFieldNote),
      ),
      AgentDraftEditableField.category => _PickerList(
        items: _filteredCategories
            .map(
              (c) => _PickerItem(
                id: c.id,
                label: c.name,
                selected: c.id == _selectedCategoryId,
              ),
            )
            .toList(),
        onSelected: _pickCategory,
      ),
      AgentDraftEditableField.account => _PickerList(
        items: widget.accounts
            .map(
              (a) => _PickerItem(
                id: a.id,
                label: _accountLabel(a),
                selected: a.id == _selectedAccountId,
              ),
            )
            .toList(),
        onSelected: _pickAccount,
      ),
      AgentDraftEditableField.direction => SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: false,
            label: Text(l10n.agentDirectionExpense),
            icon: const Icon(Icons.north_east, size: 16),
          ),
          ButtonSegment(
            value: true,
            label: Text(l10n.agentDirectionIncome),
            icon: const Icon(Icons.south_west, size: 16),
          ),
        ],
        selected: {_directionIsIncome ?? false},
        onSelectionChanged: (values) {
          setState(() => _directionIsIncome = values.first);
        },
      ),
    };
  }
}

class _PickerItem {
  const _PickerItem({
    required this.id,
    required this.label,
    required this.selected,
  });

  final String id;
  final String label;
  final bool selected;
}

class _PickerList extends StatelessWidget {
  const _PickerList({required this.items, required this.onSelected});

  final List<_PickerItem> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.label),
          trailing: item.selected
              ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => onSelected(item.id),
        );
      },
    );
  }
}
