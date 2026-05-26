import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/agent_preferences.dart';
import '../../../core/data/models/user_profile.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/ui/finko_modal_sheet_extent.dart';
import '../../../l10n/app_localizations.dart';
import '../data/user_settings_writer.dart';

Future<void> showTelegramBotPreferencesSheet({
  required BuildContext context,
  required WidgetRef ref,
  required UserProfile profile,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _TelegramBotPreferencesSheet(profile: profile),
  );
}

class _TelegramBotPreferencesSheet extends ConsumerStatefulWidget {
  const _TelegramBotPreferencesSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_TelegramBotPreferencesSheet> createState() =>
      _TelegramBotPreferencesSheetState();
}

class _TelegramBotPreferencesSheetState
    extends ConsumerState<_TelegramBotPreferencesSheet> {
  String? _localeOverride;
  String? _accountId;
  String? _expenseCategoryId;
  String? _incomeCategoryId;

  @override
  void initState() {
    super.initState();
    final p = widget.profile.agentPreferences;
    final loc = p?.localeOverride?.trim().toLowerCase();
    if (loc == 'es' || loc == 'en') {
      _localeOverride = loc;
    }
    _accountId = p?.defaultAccountId?.trim().isNotEmpty == true
        ? p!.defaultAccountId
        : null;
    _expenseCategoryId = p?.defaultExpenseCategoryId?.trim().isNotEmpty == true
        ? p!.defaultExpenseCategoryId
        : null;
    _incomeCategoryId = p?.defaultIncomeCategoryId?.trim().isNotEmpty == true
        ? p!.defaultIncomeCategoryId
        : null;
  }

  Future<void> _save(BuildContext context, AppLocalizations l10n) async {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    try {
      await ref
          .read(userSettingsWriterProvider)
          .setAgentPreferences(uid, _prefsCoercedFromStreams());
      ref.invalidate(userProfileStreamProvider);
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsErrorSave)));
      }
    }
  }

  Future<void> _clear(BuildContext context, AppLocalizations l10n) async {
    final uid = ref.read(authUidProvider);
    if (uid == null) return;
    try {
      await ref
          .read(userSettingsWriterProvider)
          .clearTelegramBotPreferences(uid);
      ref.invalidate(userProfileStreamProvider);
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsErrorSave)));
      }
    }
  }

  AgentPreferences _prefsCoercedFromStreams() {
    final accounts = ref.read(accountsStreamProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesStreamProvider).valueOrNull ?? [];
    final expenseCats = categories
        .where((c) => c.kind == CategoryKind.expense)
        .toList();
    final incomeCats = categories
        .where((c) => c.kind == CategoryKind.income)
        .toList();

    final acc = _accountId != null && accounts.any((a) => a.id == _accountId)
        ? _accountId
        : null;
    final exp =
        _expenseCategoryId != null &&
            expenseCats.any((c) => c.id == _expenseCategoryId)
        ? _expenseCategoryId
        : null;
    final inc =
        _incomeCategoryId != null &&
            incomeCats.any((c) => c.id == _incomeCategoryId)
        ? _incomeCategoryId
        : null;

    return AgentPreferences(
      localeOverride: _localeOverride,
      defaultAccountId: acc,
      defaultExpenseCategoryId: exp,
      defaultIncomeCategoryId: inc,
    );
  }

  static List<DropdownMenuItem<String?>> _withNone(
    AppLocalizations l10n,
    List<DropdownMenuItem<String?>> rest,
  ) {
    return [
      DropdownMenuItem<String?>(
        value: null,
        child: Text(l10n.settingsTelegramBotDefaultsNone),
      ),
      ...rest,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

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
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088CC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.settingsTelegramBotDefaultsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsTelegramBotDefaultsSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: accountsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (Object error, StackTrace stackTrace) =>
                        Center(child: Text(l10n.settingsErrorSave)),
                    data: (accounts) {
                      return categoriesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (Object error, StackTrace stackTrace) =>
                            Center(child: Text(l10n.settingsErrorSave)),
                        data: (categories) {
                          final expenseCats = categories
                              .where((c) => c.kind == CategoryKind.expense)
                              .toList();
                          final incomeCats = categories
                              .where((c) => c.kind == CategoryKind.income)
                              .toList();

                          final accountValue =
                              _accountId != null &&
                                  accounts.any((a) => a.id == _accountId)
                              ? _accountId
                              : null;
                          final expenseValue =
                              _expenseCategoryId != null &&
                                  expenseCats.any(
                                    (c) => c.id == _expenseCategoryId,
                                  )
                              ? _expenseCategoryId
                              : null;
                          final incomeValue =
                              _incomeCategoryId != null &&
                                  incomeCats.any(
                                    (c) => c.id == _incomeCategoryId,
                                  )
                              ? _incomeCategoryId
                              : null;

                          final localeItems = [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                l10n.settingsTelegramBotDefaultsLocaleFollow,
                              ),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'es',
                              child: Text(
                                l10n.settingsTelegramBotDefaultsLocaleEs,
                              ),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'en',
                              child: Text(
                                l10n.settingsTelegramBotDefaultsLocaleEn,
                              ),
                            ),
                          ];

                          final accountItems = _withNone(
                            l10n,
                            accounts
                                .map(
                                  (a) => DropdownMenuItem<String?>(
                                    value: a.id,
                                    child: Text('${a.name} (${a.currency})'),
                                  ),
                                )
                                .toList(),
                          );

                          final expenseItems = _withNone(
                            l10n,
                            expenseCats
                                .map(
                                  (c) => DropdownMenuItem<String?>(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                          );

                          final incomeItems = _withNone(
                            l10n,
                            incomeCats
                                .map(
                                  (c) => DropdownMenuItem<String?>(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                          );

                          return ListView(
                            children: [
                              Text(
                                l10n.settingsTelegramBotDefaultsLocale,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              DropdownButton<String?>(
                                isExpanded: true,
                                value: _localeOverride,
                                items: localeItems,
                                onChanged: (v) =>
                                    setState(() => _localeOverride = v),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.settingsTelegramBotDefaultsAccount,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              DropdownButton<String?>(
                                isExpanded: true,
                                value: accountValue,
                                items: accountItems,
                                onChanged: (v) =>
                                    setState(() => _accountId = v),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.settingsTelegramBotDefaultsExpenseCategory,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              DropdownButton<String?>(
                                isExpanded: true,
                                value: expenseValue,
                                items: expenseItems,
                                onChanged: (v) =>
                                    setState(() => _expenseCategoryId = v),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.settingsTelegramBotDefaultsIncomeCategory,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              DropdownButton<String?>(
                                isExpanded: true,
                                value: incomeValue,
                                items: incomeItems,
                                onChanged: (v) =>
                                    setState(() => _incomeCategoryId = v),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _save(context, l10n),
                  child: Text(l10n.settingsTelegramBotDefaultsSave),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _clear(context, l10n),
                  child: Text(l10n.settingsTelegramBotDefaultsClear),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
