import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_account_icons.dart';
import 'onboarding_amount_field.dart';
import 'onboarding_input_styles.dart';
import 'onboarding_money_parsing.dart';

/// Fixed account color tokens (ARGB).
const List<int> kOnboardingAccountColorPalette = <int>[
  0xFF2196F3,
  0xFF4CAF50,
  0xFFFF9800,
  0xFF9C27B0,
  0xFFE91E63,
  0xFF00BCD4,
  0xFFFFC107,
  0xFF607D8B,
];

const List<String> kOnboardingCurrencies = <String>['MXN', 'USD', 'EUR'];

String accountTypeLabel(AppLocalizations l10n, OnboardingAccountType t) {
  return switch (t) {
    OnboardingAccountType.checking => l10n.accountTypeChecking,
    OnboardingAccountType.savings => l10n.accountTypeSavings,
    OnboardingAccountType.investment => l10n.accountTypeInvestment,
    OnboardingAccountType.creditCard => l10n.accountTypeCreditCard,
    OnboardingAccountType.loan => l10n.accountTypeLoan,
    OnboardingAccountType.mortgage => l10n.accountTypeMortgage,
  };
}

/// Modal bottom sheet editor for add/edit account (name, type, currency, color, starting balance).
Future<void> showOnboardingAccountEditor({
  required BuildContext context,
  required AppLocalizations l10n,
  OnboardingAccountDraft? existing,
  required void Function(OnboardingAccountDraft draft) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return _OnboardingAccountEditorSheet(
        l10n: l10n,
        existing: existing,
        onSave: onSave,
      );
    },
  );
}

class _OnboardingAccountEditorSheet extends StatefulWidget {
  const _OnboardingAccountEditorSheet({
    required this.l10n,
    this.existing,
    required this.onSave,
  });

  final AppLocalizations l10n;
  final OnboardingAccountDraft? existing;
  final void Function(OnboardingAccountDraft draft) onSave;

  @override
  State<_OnboardingAccountEditorSheet> createState() =>
      _OnboardingAccountEditorSheetState();
}

class _OnboardingAccountEditorSheetState
    extends State<_OnboardingAccountEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  late OnboardingAccountType _type;
  late String _currency;
  late int _colorArgb;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _balanceController = TextEditingController(
      text: existing != null && existing.startingBalanceMinor != 0
          ? formatMinorAsInputString(existing.startingBalanceMinor)
          : '',
    );
    _type = existing?.type ?? OnboardingAccountType.checking;
    _currency = existing?.currency ?? 'MXN';
    _colorArgb = existing?.colorArgb ?? kOnboardingAccountColorPalette.first;
    _iconKey = existing?.iconKey ?? defaultAccountIconKeyForType(_type);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
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
                  ? l10n.onboardingAddAccount
                  : l10n.onboardingEditAccount,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
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
                itemCount: kOnboardingAccountIconMap.length,
                itemBuilder: (context, i) {
                  final key = kOnboardingAccountIconMap.keys.elementAt(i);
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
                      child: Icon(onboardingAccountIconForKey(key)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.onboardingAccountName,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<OnboardingAccountType>(
              key: ValueKey<OnboardingAccountType>(_type),
              initialValue: _type,
              decoration: InputDecoration(
                labelText: l10n.onboardingAccountTypeLabel,
              ),
              items: OnboardingAccountType.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(accountTypeLabel(l10n, e)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey<String>(_currency),
                    initialValue: _currency,
                    decoration: InputDecoration(
                      labelText: l10n.onboardingCurrencyLabel,
                    ),
                    items: kOnboardingCurrencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v ?? _currency),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OnboardingAmountTextField(
                    controller: _balanceController,
                    decoration: onboardingMoneyDecoration(
                      context: context,
                      labelText: l10n.onboardingStartingBalanceLabel,
                      currencyCode: _currency,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingSectionColor,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final argb in kOnboardingAccountColorPalette)
                  GestureDetector(
                    onTap: () => setState(() => _colorArgb = argb),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(argb),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorArgb == argb
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                final minor = parseMajorToMinor(_balanceController.text) ?? 0;
                widget.onSave(
                  OnboardingAccountDraft(
                    id:
                        existing?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                    type: _type,
                    currency: _currency,
                    colorArgb: _colorArgb,
                    startingBalanceMinor: minor,
                    iconKey: _iconKey,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Text(l10n.onboardingSaveAccount),
            ),
          ],
        ),
      ),
    );
  }
}
