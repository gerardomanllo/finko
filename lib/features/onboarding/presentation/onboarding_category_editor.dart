import 'package:flutter/material.dart';

import '../../../core/data/ledger_category_ids.dart';
import '../../../core/ui/finko_modal_sheet_extent.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_amount_field.dart';
import 'onboarding_category_icons.dart';
import 'onboarding_color_palette.dart';
import 'onboarding_icon_labels.dart';
import 'onboarding_input_styles.dart';
import 'onboarding_money_parsing.dart';

double _onboardingCategoryDropdownItemMaxWidth(BuildContext context) {
  return (MediaQuery.sizeOf(context).width - 64).clamp(200.0, 560.0);
}

Widget _categoryColorMenuRow(BuildContext context, OnboardingNamedColor color) {
  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: _onboardingCategoryDropdownItemMaxWidth(context),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Color(color.argb),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            onboardingColorLabel(color, Localizations.localeOf(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    ),
  );
}

/// See account editor: [ListTile] in dropdowns breaks the collapsed "selected" row
/// (infinite width + ~24px height).
Widget _onboardingCategoryIconMenuRow(
  BuildContext context,
  IconData icon,
  String iconKey,
) {
  final locale = Localizations.localeOf(context);
  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: _onboardingCategoryDropdownItemMaxWidth(context),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            onboardingCategoryIconLabel(iconKey, locale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    ),
  );
}

/// Add/edit category in a bottom sheet (parity with accounts).
Future<void> showOnboardingCategoryEditor({
  required BuildContext context,
  required AppLocalizations l10n,
  OnboardingCategoryDraft? existing,
  required void Function(OnboardingCategoryDraft draft) onSave,
  bool lockKind = false,
  Future<bool> Function()? onDelete,

  /// When true and [monthlyBudgetCurrencyCode] is non-empty, shows a monthly
  /// budget field (main currency minor units) and sets
  /// [OnboardingCategoryDraft.monthlyBudgetTargetMinorMain] on save.
  bool editMonthlyBudgetMain = false,
  String? monthlyBudgetCurrencyCode,
  int initialMonthlyBudgetTargetMinorMain = 0,
  bool showFixedExpenseToggle = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _OnboardingCategoryEditorSheet(
      l10n: l10n,
      existing: existing,
      onSave: onSave,
      lockKind: lockKind,
      onDelete: onDelete,
      editMonthlyBudgetMain: editMonthlyBudgetMain,
      monthlyBudgetCurrencyCode: monthlyBudgetCurrencyCode,
      initialMonthlyBudgetTargetMinorMain: initialMonthlyBudgetTargetMinorMain,
      showFixedExpenseToggle: showFixedExpenseToggle,
    ),
  );
}

class _OnboardingCategoryEditorSheet extends StatefulWidget {
  const _OnboardingCategoryEditorSheet({
    required this.l10n,
    this.existing,
    required this.onSave,
    this.lockKind = false,
    this.onDelete,
    this.editMonthlyBudgetMain = false,
    this.monthlyBudgetCurrencyCode,
    this.initialMonthlyBudgetTargetMinorMain = 0,
    this.showFixedExpenseToggle = false,
  });

  final AppLocalizations l10n;
  final OnboardingCategoryDraft? existing;
  final void Function(OnboardingCategoryDraft draft) onSave;
  final bool lockKind;
  final Future<bool> Function()? onDelete;
  final bool editMonthlyBudgetMain;
  final String? monthlyBudgetCurrencyCode;
  final int initialMonthlyBudgetTargetMinorMain;
  final bool showFixedExpenseToggle;

  @override
  State<_OnboardingCategoryEditorSheet> createState() =>
      _OnboardingCategoryEditorSheetState();
}

class _OnboardingCategoryEditorSheetState
    extends State<_OnboardingCategoryEditorSheet> {
  late final TextEditingController _nameController;
  late OnboardingCategoryKind _kind;
  late String _iconKey;
  late int _colorArgb;
  late bool _isFixedExpense;
  TextEditingController? _budgetController;

  bool get _showBudgetField =>
      widget.editMonthlyBudgetMain &&
      (widget.monthlyBudgetCurrencyCode?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _kind = e?.kind ?? OnboardingCategoryKind.expense;
    _iconKey = e?.iconKey ?? 'home';
    _colorArgb = e?.colorArgb != null
        ? onboardingNearestNamedColor(e!.colorArgb!).argb
        : kOnboardingNamedColors.first.argb;
    _isFixedExpense = e?.isFixedExpense ?? false;
    if (_showBudgetField) {
      _budgetController = TextEditingController(
        text: formatMinorAsInputString(
          widget.initialMonthlyBudgetTargetMinorMain,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final existing = widget.existing;

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
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null
                        ? l10n.onboardingAddCategory
                        : l10n.onboardingEditCategory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingCategoryName,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  IgnorePointer(
                    ignoring: widget.lockKind,
                    child: Opacity(
                      opacity: widget.lockKind ? 0.45 : 1,
                      child: SegmentedButton<OnboardingCategoryKind>(
                        segments: [
                          ButtonSegment(
                            value: OnboardingCategoryKind.income,
                            label: Text(l10n.onboardingCategoryKindIncome),
                          ),
                          ButtonSegment(
                            value: OnboardingCategoryKind.expense,
                            label: Text(l10n.onboardingCategoryKindExpense),
                          ),
                        ],
                        selected: <OnboardingCategoryKind>{_kind},
                        onSelectionChanged: (s) =>
                            setState(() => _kind = s.first),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.onboardingPickIcon,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(_iconKey),
                    initialValue:
                        kOnboardingCategoryIconMap.containsKey(_iconKey)
                        ? _iconKey
                        : kOnboardingCategoryIconMap.keys.first,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingPickIcon,
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (BuildContext c) {
                      return [
                        for (final e in kOnboardingCategoryIconMap.entries)
                          _onboardingCategoryIconMenuRow(c, e.value, e.key),
                      ];
                    },
                    items: [
                      for (final e in kOnboardingCategoryIconMap.entries)
                        DropdownMenuItem<String>(
                          value: e.key,
                          child: _onboardingCategoryIconMenuRow(
                            context,
                            e.value,
                            e.key,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _iconKey = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.onboardingSectionColor,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    key: ValueKey<int>(_colorArgb),
                    initialValue: onboardingNearestNamedColor(_colorArgb).argb,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingSectionColor,
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (BuildContext c) {
                      return [
                        for (final named in kOnboardingNamedColors)
                          _categoryColorMenuRow(c, named),
                      ];
                    },
                    items: [
                      for (final named in kOnboardingNamedColors)
                        DropdownMenuItem<int>(
                          value: named.argb,
                          child: _categoryColorMenuRow(context, named),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _colorArgb = v);
                    },
                  ),
                  if (widget.showFixedExpenseToggle &&
                      _kind == OnboardingCategoryKind.expense) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.categoryFixedExpenseToggle),
                      subtitle: Text(
                        l10n.categoryFixedExpenseToggleHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: _isFixedExpense,
                      onChanged: (v) => setState(() => _isFixedExpense = v),
                    ),
                  ],
                  if (_showBudgetField) ...[
                    const SizedBox(height: 16),
                    OnboardingAmountTextField(
                      controller: _budgetController!,
                      decoration: onboardingMoneyDecoration(
                        context: context,
                        labelText: l10n.categoryEditorMonthlyBudgetLabel,
                        currencyCode: widget.monthlyBudgetCurrencyCode!.trim(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (widget.onDelete != null &&
                      existing != null &&
                      !existing.isSystem &&
                      existing.id != kLedgerTransferCategoryId) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          final removed = await widget.onDelete!();
                          if (removed && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          l10n.categoryEditorDeleteCategory,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      final int? budgetMinor = _showBudgetField
                          ? (parseMajorToMinor(_budgetController!.text) ?? 0)
                          : null;
                      widget.onSave(
                        OnboardingCategoryDraft(
                          id:
                              existing?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          name: name,
                          kind: _kind,
                          iconKey: _iconKey,
                          isSystem: existing?.isSystem ?? false,
                          colorArgb: _colorArgb,
                          isFixedExpense:
                              _kind == OnboardingCategoryKind.expense
                              ? _isFixedExpense
                              : false,
                          monthlyBudgetTargetMinorMain: budgetMinor,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.onboardingSaveCategory),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
