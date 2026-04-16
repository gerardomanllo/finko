import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_category_icons.dart';

/// Add/edit category in a bottom sheet (parity with accounts).
Future<void> showOnboardingCategoryEditor({
  required BuildContext context,
  required AppLocalizations l10n,
  OnboardingCategoryDraft? existing,
  required void Function(OnboardingCategoryDraft draft) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _OnboardingCategoryEditorSheet(
      l10n: l10n,
      existing: existing,
      onSave: onSave,
    ),
  );
}

class _OnboardingCategoryEditorSheet extends StatefulWidget {
  const _OnboardingCategoryEditorSheet({
    required this.l10n,
    this.existing,
    required this.onSave,
  });

  final AppLocalizations l10n;
  final OnboardingCategoryDraft? existing;
  final void Function(OnboardingCategoryDraft draft) onSave;

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

    return Padding(
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
            SegmentedButton<OnboardingCategoryKind>(
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
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingPickIcon,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: kOnboardingCategoryIconMap.length,
                itemBuilder: (context, i) {
                  final key = kOnboardingCategoryIconMap.keys.elementAt(i);
                  final selected = _iconKey == key;
                  return InkWell(
                    onTap: () => setState(() => _iconKey = key),
                    borderRadius: BorderRadius.circular(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(onboardingIconForKey(key)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
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
                    isSystem: false,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Text(l10n.onboardingSaveCategory),
            ),
          ],
        ),
      ),
    );
  }
}
