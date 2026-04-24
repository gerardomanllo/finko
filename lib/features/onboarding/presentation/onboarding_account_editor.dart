import 'package:flutter/material.dart';

import '../../../core/ui/finko_modal_sheet_extent.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_account_icons.dart';
import 'onboarding_amount_field.dart';
import 'onboarding_color_palette.dart';
import 'onboarding_icon_labels.dart';
import 'onboarding_input_styles.dart';
import 'onboarding_money_parsing.dart';

/// Named color ARGBs exposed as `List<int>` for callers that only need the value.
/// Labels come from [kOnboardingNamedColors] via [onboardingColorLabel].
List<int> get kOnboardingAccountColorPalette => [
  for (final c in kOnboardingNamedColors) c.argb,
];

const List<String> kOnboardingCurrencies = <String>['MXN', 'USD', 'EUR'];

/// Max width for dropdown item rows (overlay + **collapsed** selected row need finite width).
double _onboardingAccountDropdownItemMaxWidth(BuildContext context) {
  return (MediaQuery.sizeOf(context).width - 64).clamp(200.0, 560.0);
}

/// Icon + localized label row for [DropdownMenuItem] and [DropdownButtonFormField.selectedItemBuilder].
/// Avoids [ListTile] (bad constraints when the button shows the child at ~1 line height).
Widget _onboardingIconDropdownItemRow(
  BuildContext context,
  IconData icon,
  String iconKey,
) {
  final locale = Localizations.localeOf(context);
  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: _onboardingAccountDropdownItemMaxWidth(context),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            onboardingAccountIconLabel(iconKey, locale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    ),
  );
}

/// Color swatch + **localized name** row (no hex). Same width rules as the icon row.
Widget _onboardingColorDropdownItemRow(
  BuildContext context,
  OnboardingNamedColor color,
) {
  final locale = Localizations.localeOf(context);
  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: _onboardingAccountDropdownItemMaxWidth(context),
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
            onboardingColorLabel(color, locale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    ),
  );
}

String accountTypeLabel(AppLocalizations l10n, OnboardingAccountType t) {
  return switch (t) {
    OnboardingAccountType.cash => l10n.accountTypeCash,
    OnboardingAccountType.checking => l10n.accountTypeChecking,
    OnboardingAccountType.savings => l10n.accountTypeSavings,
    OnboardingAccountType.investment => l10n.accountTypeInvestment,
    OnboardingAccountType.creditCard => l10n.accountTypeCreditCard,
    OnboardingAccountType.loan => l10n.accountTypeLoan,
    OnboardingAccountType.mortgage => l10n.accountTypeMortgage,
  };
}

/// Modal bottom sheet editor for add/edit account (name, type, currency, color, starting balance).
///
/// When [metadataOnly] is true and [existing] is non-null, **type** and **currency** are read-only,
/// the starting balance field is hidden, and only **name**, **icon**, and **color** are editable
/// (balances and money semantics come from the ledger).
Future<void> showOnboardingAccountEditor({
  required BuildContext context,
  required AppLocalizations l10n,
  OnboardingAccountDraft? existing,
  required void Function(OnboardingAccountDraft draft) onSave,
  bool metadataOnly = false,
  Future<bool> Function()? onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      return _OnboardingAccountEditorSheet(
        l10n: l10n,
        existing: existing,
        onSave: onSave,
        metadataOnly: metadataOnly,
        onDelete: onDelete,
      );
    },
  );
}

class _OnboardingAccountEditorSheet extends StatefulWidget {
  const _OnboardingAccountEditorSheet({
    required this.l10n,
    this.existing,
    required this.onSave,
    this.metadataOnly = false,
    this.onDelete,
  });

  final AppLocalizations l10n;
  final OnboardingAccountDraft? existing;
  final void Function(OnboardingAccountDraft draft) onSave;
  final bool metadataOnly;
  final Future<bool> Function()? onDelete;

  @override
  State<_OnboardingAccountEditorSheet> createState() =>
      _OnboardingAccountEditorSheetState();
}

class _OnboardingAccountEditorSheetState
    extends State<_OnboardingAccountEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _creditLimitController;

  late OnboardingAccountType _type;
  late String _currency;
  late int _colorArgb;
  late String _iconKey;

  bool get _isSystemCash =>
      widget.existing?.id == OnboardingDraft.kSystemCashAccountId &&
      widget.existing?.isSystem == true;

  Iterable<OnboardingAccountType> get _selectableTypes => OnboardingAccountType
      .values
      .where((e) => e != OnboardingAccountType.cash);

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
    final limit = existing?.creditLimitMinor;
    _creditLimitController = TextEditingController(
      text: limit != null && limit > 0 ? formatMinorAsInputString(limit) : '',
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
    _creditLimitController.dispose();
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
                        ? l10n.onboardingAddAccount
                        : l10n.onboardingEditAccount,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (!_isSystemCash) ...[
                    Text(
                      l10n.onboardingPickIcon,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(_iconKey),
                      initialValue:
                          kOnboardingAccountIconMap.containsKey(_iconKey)
                          ? _iconKey
                          : kOnboardingAccountIconMap.keys.first,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingPickIcon,
                      ),
                      isExpanded: true,
                      selectedItemBuilder: (BuildContext c) {
                        return [
                          for (final e in kOnboardingAccountIconMap.entries)
                            _onboardingIconDropdownItemRow(c, e.value, e.key),
                        ];
                      },
                      items: [
                        for (final e in kOnboardingAccountIconMap.entries)
                          DropdownMenuItem<String>(
                            value: e.key,
                            child: _onboardingIconDropdownItemRow(
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
                  ],
                  if (_isSystemCash) ...[
                    Text(
                      l10n.onboardingAccountNameCash,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                  ] else
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingAccountName,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  if (!_isSystemCash) const SizedBox(height: 12),
                  if (widget.metadataOnly && existing != null) ...[
                    Text(
                      l10n.onboardingAccountTypeLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accountTypeLabel(l10n, existing.type),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboardingCurrencyLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      existing.currency,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ] else if (_isSystemCash) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(_currency),
                      initialValue: _currency,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingCurrencyLabel,
                      ),
                      items: kOnboardingCurrencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _currency = v ?? _currency),
                    ),
                    if (!widget.metadataOnly) ...[
                      const SizedBox(height: 12),
                      OnboardingAmountTextField(
                        controller: _balanceController,
                        decoration: onboardingMoneyDecoration(
                          context: context,
                          labelText: l10n.onboardingStartingBalanceLabel,
                          currencyCode: _currency,
                        ),
                      ),
                    ],
                  ] else ...[
                    DropdownButtonFormField<OnboardingAccountType>(
                      key: ValueKey<OnboardingAccountType>(_type),
                      initialValue: _type,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingAccountTypeLabel,
                      ),
                      isExpanded: true,
                      items: _selectableTypes
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(accountTypeLabel(l10n, e)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _type = v ?? _type;
                        _iconKey = defaultAccountIconKeyForType(_type);
                      }),
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
                            isExpanded: true,
                            items: kOnboardingCurrencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
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
                    if (_type == OnboardingAccountType.creditCard) ...[
                      const SizedBox(height: 12),
                      OnboardingAmountTextField(
                        controller: _creditLimitController,
                        decoration: onboardingMoneyDecoration(
                          context: context,
                          labelText: l10n.onboardingCreditLimitLabel,
                          currencyCode: _currency,
                        ),
                      ),
                    ],
                  ],
                  if (!_isSystemCash) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.onboardingSectionColor,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      key: ValueKey<int>(_colorArgb),
                      initialValue: onboardingNearestNamedColor(
                        _colorArgb,
                      ).argb,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingSectionColor,
                      ),
                      isExpanded: true,
                      selectedItemBuilder: (BuildContext c) {
                        return [
                          for (final color in kOnboardingNamedColors)
                            _onboardingColorDropdownItemRow(c, color),
                        ];
                      },
                      items: [
                        for (final color in kOnboardingNamedColors)
                          DropdownMenuItem<int>(
                            value: color.argb,
                            child: _onboardingColorDropdownItemRow(
                              context,
                              color,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _colorArgb = v);
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (widget.onDelete != null &&
                      existing != null &&
                      !existing.isSystem) ...[
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
                          l10n.accountEditorDeleteAccount,
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
                      final locked = widget.metadataOnly && existing != null;
                      final name = _isSystemCash
                          ? (existing!.name)
                          : _nameController.text.trim();
                      if (!_isSystemCash && name.isEmpty) return;
                      final minor = locked
                          ? 0
                          : (parseMajorToMinor(_balanceController.text) ?? 0);
                      final lockedTypeCurrency =
                          widget.metadataOnly && existing != null;
                      int? creditLimit;
                      if (!locked &&
                          !lockedTypeCurrency &&
                          _type == OnboardingAccountType.creditCard) {
                        creditLimit = parseMajorToMinor(
                          _creditLimitController.text,
                        );
                      } else if (lockedTypeCurrency &&
                          existing.type == OnboardingAccountType.creditCard) {
                        creditLimit = existing.creditLimitMinor;
                      }
                      widget.onSave(
                        OnboardingAccountDraft(
                          id:
                              existing?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          name: name,
                          type: lockedTypeCurrency ? existing.type : _type,
                          currency: lockedTypeCurrency
                              ? existing.currency
                              : _currency,
                          colorArgb: _colorArgb,
                          startingBalanceMinor: minor,
                          iconKey: _iconKey,
                          isSystem: existing?.isSystem ?? false,
                          creditLimitMinor: creditLimit,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.onboardingSaveAccount),
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
