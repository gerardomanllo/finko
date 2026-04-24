import 'package:flutter/material.dart';

import '../../../core/data/ledger_category_ids.dart';
import '../../../core/ui/finko_modal_sheet_extent.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_category_icons.dart';
import 'onboarding_icon_labels.dart';

double _onboardingCategoryDropdownItemMaxWidth(BuildContext context) {
  return (MediaQuery.sizeOf(context).width - 64).clamp(200.0, 560.0);
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
  });

  final AppLocalizations l10n;
  final OnboardingCategoryDraft? existing;
  final void Function(OnboardingCategoryDraft draft) onSave;
  final bool lockKind;
  final Future<bool> Function()? onDelete;

  @override
  State<_OnboardingCategoryEditorSheet> createState() =>
      _OnboardingCategoryEditorSheetState();
}

class _OnboardingCategoryEditorSheetState
    extends State<_OnboardingCategoryEditorSheet> {
  late final TextEditingController _nameController;
  late OnboardingCategoryKind _kind;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _kind = e?.kind ?? OnboardingCategoryKind.expense;
    _iconKey = e?.iconKey ?? 'home';
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                      widget.onSave(
                        OnboardingCategoryDraft(
                          id:
                              existing?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          name: name,
                          kind: _kind,
                          iconKey: _iconKey,
                          isSystem: existing?.isSystem ?? false,
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
