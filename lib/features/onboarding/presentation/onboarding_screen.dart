import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/models/user_profile.dart' show kDefaultMainCurrency;
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/locale/locale_notifier.dart';
import '../../../core/locale/locale_support.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import '../application/onboarding_state.dart';
import '../data/onboarding_timezones.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_account_editor.dart';
import 'onboarding_account_icons.dart';
import 'onboarding_amount_field.dart';
import 'onboarding_category_editor.dart';
import 'onboarding_category_icons.dart';
import 'onboarding_input_styles.dart';
import 'onboarding_messaging_sheet.dart';
import 'onboarding_money_parsing.dart';
import 'onboarding_projected_chart.dart';
import 'onboarding_review_summary.dart';

String _validationMessage(AppLocalizations l10n, String? code) {
  if (code == null) return '';
  return switch (code) {
    'profileNameRequired' => l10n.onboardingValidationProfileNameRequired,
    'profileNameTooLong' => l10n.onboardingValidationProfileNameTooLong,
    'accountsMinOne' => l10n.onboardingValidationAccountsMinOne,
    'accountNameRequired' => l10n.onboardingValidationAccountNameRequired,
    'categoriesMissingFixed' => l10n.onboardingValidationCategoriesFixed,
    'recurringAmount' => l10n.onboardingValidationRecurringAmount,
    'recurringAccount' => l10n.onboardingValidationRecurringAccount,
    'recurringDaysTwice' => l10n.onboardingValidationRecurringDaysTwice,
    'recurringDayMonthly' => l10n.onboardingValidationRecurringDayMonthly,
    'recurringDayRange' => l10n.onboardingValidationRecurringDayRange,
    'recurringWeekday' => l10n.onboardingValidationRecurringWeekday,
    'budgetMissing' => l10n.onboardingValidationBudgetMissing,
    _ => code,
  };
}

String _timezoneLabel(AppLocalizations l10n, String labelKey) {
  return switch (labelKey) {
    'onboardingTimezoneMexicoSoutheast' =>
      l10n.onboardingTimezoneMexicoSoutheast,
    'onboardingTimezoneMexicoCentral' => l10n.onboardingTimezoneMexicoCentral,
    'onboardingTimezoneMexicoPacific' => l10n.onboardingTimezoneMexicoPacific,
    'onboardingTimezoneMexicoNorthwest' =>
      l10n.onboardingTimezoneMexicoNorthwest,
    'onboardingTimezoneUsPacific' => l10n.onboardingTimezoneUsPacific,
    'onboardingTimezoneUsMountain' => l10n.onboardingTimezoneUsMountain,
    'onboardingTimezoneUsEastern' => l10n.onboardingTimezoneUsEastern,
    _ => labelKey,
  };
}

String _cadenceLabel(AppLocalizations l10n, OnboardingCadence c) {
  return switch (c) {
    OnboardingCadence.monthly => l10n.onboardingCadenceMonthly,
    OnboardingCadence.biweekly => l10n.onboardingCadenceBiweekly,
    OnboardingCadence.weekly => l10n.onboardingCadenceWeekly,
  };
}

String _narrowWeekdayLabel(BuildContext context, int weekday) {
  final d = DateTime(2024, 1, 1 + (weekday - 1));
  return DateFormat.E(Localizations.localeOf(context).toString()).format(d);
}

String _bcpLocaleFromDraft(String locale) {
  final t = locale.trim();
  if (t.isEmpty) return 'es-MX';
  if (t.toLowerCase().startsWith('en')) {
    return t.contains('-') ? t : 'en-US';
  }
  return t.contains('-') ? t : 'es-MX';
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _otpController;
  late final TextEditingController _waController;
  late final TextEditingController _tgController;
  String _timezone = 'America/Mexico_City';
  String _themeChoice = 'system';
  String _localeChoice = 'es-MX';
  String _mainCurrency = kDefaultMainCurrency;

  final Map<String, TextEditingController> _budgetControllers = {};

  bool _budgetsControllersReady = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).draft;
    _nameController = TextEditingController(text: draft.displayName);
    _otpController = TextEditingController();
    _waController = TextEditingController(
      text: draft.messaging.whatsAppId ?? '',
    );
    _tgController = TextEditingController(
      text: draft.messaging.telegramId ?? '',
    );
    _timezone = draft.timezone;
    _themeChoice = draft.themePreference;
    _localeChoice = _bcpLocaleFromDraft(draft.locale);
    _mainCurrency = draft.mainCurrency;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(themeModeProvider.notifier).setFromPreference(_themeChoice);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _otpController.dispose();
    _waController.dispose();
    _tgController.dispose();
    for (final c in _budgetControllers.values) {
      c.dispose();
    }
    _budgetControllers.clear();
    super.dispose();
  }

  void _disposeBudgetControllers() {
    for (final c in _budgetControllers.values) {
      c.dispose();
    }
    _budgetControllers.clear();
    _budgetsControllersReady = false;
  }

  void _ensureBudgetControllers(OnboardingDraft draft) {
    for (final cat in draft.categories) {
      final minor = draft.budgetsMinorByCategory[cat.id] ?? 0;
      final text = formatMinorAsInputString(minor);
      final existing = _budgetControllers[cat.id];
      if (existing == null) {
        _budgetControllers[cat.id] = TextEditingController(text: text);
      } else {
        final parsed = parseMajorToMinor(existing.text) ?? 0;
        if (!_budgetsControllersReady || parsed != minor) {
          existing.text = text;
        }
      }
    }
    _budgetsControllersReady = true;
  }

  Future<void> _onPrimaryPressed(
    OnboardingState state,
    AppLocalizations l10n,
  ) async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.updateProfile(
      displayName: _nameController.text,
      timezone: _timezone,
      themePreference: _themeChoice,
      locale: _localeChoice,
      mainCurrency: _mainCurrency,
    );
    controller.setMessaging(
      OnboardingMessagingState(
        whatsAppId: _waController.text.trim().isEmpty
            ? null
            : _waController.text.trim(),
        telegramId: _tgController.text.trim().isEmpty
            ? null
            : _tgController.text.trim(),
        whatsAppVerified: state.draft.messaging.whatsAppVerified,
        telegramVerified: state.draft.messaging.telegramVerified,
      ),
    );

    final ok = await controller.next();
    if (!mounted || !ok) return;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toString();

    ref.listen(onboardingControllerProvider.select((s) => s.step), (
      prev,
      next,
    ) {
      if (next == OnboardingStep.categories && mounted) {
        controller.syncFixedExpensesDisplayName(
          l10n.onboardingCategoryFixedExpenses,
        );
      }
      if (next == OnboardingStep.accounts && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(onboardingControllerProvider.notifier)
              .syncSystemCashDisplayName(l10n.onboardingAccountNameCash);
        });
      }
      if (prev == OnboardingStep.budgets && next != OnboardingStep.budgets) {
        _disposeBudgetControllers();
      }
      if (prev != OnboardingStep.completion &&
          next == OnboardingStep.completion &&
          mounted) {
        final ymDevice = ref.read(currentYearMonthProvider);
        final ymDash = ref.read(dashboardYearMonthProvider);
        ref.invalidate(userProfileStreamProvider);
        ref.invalidate(accountsStreamProvider);
        ref.invalidate(categoriesStreamProvider);
        ref.invalidate(recurringRulesStreamProvider);
        ref.invalidate(upcomingTransactionsStreamProvider);
        ref.invalidate(currentMonthTotalsStreamProvider);
        ref.invalidate(monthlyTotalsForMonthStreamProvider(ymDevice));
        if (ymDash != ymDevice) {
          ref.invalidate(monthlyTotalsForMonthStreamProvider(ymDash));
        }
        context.go('/dashboard');
      }
    });

    ref.listen(onboardingControllerProvider, (prev, next) {
      if (next.step == OnboardingStep.budgets) {
        _ensureBudgetControllers(next.draft);
      }
    });

    final validationText = _validationMessage(l10n, state.validationCode);
    final canProceed = controller.validateCurrentStep();
    final showNav =
        state.step != OnboardingStep.commit &&
        state.step != OnboardingStep.completion;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForStep(l10n, state.step)),
        actions: [
          if (state.step == OnboardingStep.profile)
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(authRepositoryProvider).signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.loginErrorGeneric)),
                    );
                  }
                }
              },
              child: Text(l10n.settingsSignOut),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Semantics(
                header: true,
                label: _titleForStep(l10n, state.step),
                child: ExcludeSemantics(
                  child: _TypewriterTitle(
                    text: _titleForStep(l10n, state.step),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: LinearProgressIndicator(value: state.progress),
            ),
            if (validationText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              validationText,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: controller.clearValidation,
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (state.commitErrorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              state.commitErrorMessage!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: controller.clearCommitError,
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: state.step == OnboardingStep.projectedSavings
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: _buildProjectedStep(
                        context,
                        l10n,
                        state.draft,
                        localeTag,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildStepBody(
                          context,
                          state,
                          l10n,
                          localeTag,
                          controller,
                        ),
                      ],
                    ),
            ),
            if (showNav)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    if (state.canGoBack)
                      OutlinedButton(
                        onPressed: controller.back,
                        child: Text(l10n.onboardingBack),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: state.isSubmitting || !canProceed
                          ? null
                          : () => _onPrimaryPressed(state, l10n),
                      child: Text(_primaryLabel(l10n, state.step)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _primaryLabel(AppLocalizations l10n, OnboardingStep step) {
    if (step == OnboardingStep.projectedSavings) return l10n.onboardingContinue;
    if (step == OnboardingStep.review) return l10n.onboardingCommit;
    return l10n.onboardingNext;
  }

  Widget _buildStepBody(
    BuildContext context,
    OnboardingState state,
    AppLocalizations l10n,
    String localeTag,
    OnboardingController controller,
  ) {
    final draft = state.draft;
    switch (state.step) {
      case OnboardingStep.profile:
        return _buildProfileStep(context, l10n, controller);
      case OnboardingStep.accounts:
        return _buildAccountsStep(context, l10n, draft, controller);
      case OnboardingStep.categories:
        return _buildCategoriesStep(context, l10n, draft, controller);
      case OnboardingStep.recurringIncome:
        return _buildRecurringStep(context, l10n, draft, controller);
      case OnboardingStep.budgets:
        return _buildBudgetsStep(context, l10n, draft, controller, localeTag);
      case OnboardingStep.projectedSavings:
        return _buildProjectedStep(context, l10n, draft, localeTag);
      case OnboardingStep.messaging:
        return _buildMessagingStep(context, l10n, draft, controller);
      case OnboardingStep.review:
        return buildOnboardingReviewSummary(context, draft, l10n, localeTag);
      case OnboardingStep.commit:
        return const Center(child: CircularProgressIndicator());
      case OnboardingStep.completion:
        return Text(l10n.onboardingCompleted);
    }
  }

  Widget _buildProfileStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          maxLength: OnboardingController.kMaxDisplayNameLength,
          decoration: InputDecoration(
            labelText: l10n.onboardingDisplayNameLabel,
          ),
          onChanged: (_) => controller.updateProfile(
            displayName: _nameController.text,
            timezone: _timezone,
            themePreference: _themeChoice,
            locale: _localeChoice,
            mainCurrency: _mainCurrency,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(_timezone),
          initialValue: _timezone,
          decoration: InputDecoration(labelText: l10n.onboardingTimezoneLabel),
          items: [
            for (final opt in kOnboardingTimezoneOptions)
              DropdownMenuItem<String>(
                value: opt.ianaId,
                child: Text(_timezoneLabel(l10n, opt.labelKey)),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _timezone = v);
            controller.updateProfile(
              displayName: _nameController.text,
              timezone: _timezone,
              themePreference: _themeChoice,
              locale: _localeChoice,
              mainCurrency: _mainCurrency,
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(_themeChoice),
          initialValue: _themeChoice,
          decoration: InputDecoration(labelText: l10n.onboardingThemeLabel),
          items: [
            DropdownMenuItem(value: 'light', child: Text(l10n.themeLight)),
            DropdownMenuItem(value: 'dark', child: Text(l10n.themeDark)),
            DropdownMenuItem(value: 'system', child: Text(l10n.themeAutomatic)),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _themeChoice = v);
            ref.read(themeModeProvider.notifier).setFromPreference(v);
            controller.updateProfile(
              displayName: _nameController.text,
              timezone: _timezone,
              themePreference: _themeChoice,
              locale: _localeChoice,
              mainCurrency: _mainCurrency,
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(_localeChoice),
          initialValue: _localeChoice,
          decoration: InputDecoration(labelText: l10n.onboardingLocaleLabel),
          items: [
            DropdownMenuItem(
              value: 'es-MX',
              child: Text(l10n.onboardingLocaleSpanishMx),
            ),
            DropdownMenuItem(
              value: 'en-US',
              child: Text(l10n.onboardingLocaleEnglishUs),
            ),
          ],
          onChanged: (v) async {
            if (v == null) return;
            setState(() => _localeChoice = v);
            await ref
                .read(localeNotifierProvider.notifier)
                .setLocale(localeFromBcp47(v));
            controller.updateProfile(
              displayName: _nameController.text,
              timezone: _timezone,
              themePreference: _themeChoice,
              locale: _localeChoice,
              mainCurrency: _mainCurrency,
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(_mainCurrency),
          initialValue: _mainCurrency,
          decoration: InputDecoration(
            labelText: l10n.onboardingMainCurrencyLabel,
          ),
          items: [
            for (final c in kOnboardingCurrencies)
              DropdownMenuItem<String>(value: c, child: Text(c)),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _mainCurrency = v);
            controller.updateProfile(
              displayName: _nameController.text,
              timezone: _timezone,
              themePreference: _themeChoice,
              locale: _localeChoice,
              mainCurrency: _mainCurrency,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountsStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    OnboardingController controller,
  ) {
    final localeTag = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...draft.accounts.map((a) {
          final balanceText = formatMinorUnits(
            a.startingBalanceMinor,
            a.currency,
            localeTag,
          );
          final displayName = a.id == OnboardingDraft.kSystemCashAccountId
              ? l10n.onboardingAccountNameCash
              : a.name;
          return InkWell(
            onTap: () => showOnboardingAccountEditor(
              context: context,
              l10n: l10n,
              existing: a,
              onSave: controller.updateAccount,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    onboardingAccountIconForKey(a.iconKey),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(accountTypeLabel(l10n, a.type)),
                        const SizedBox(height: 2),
                        Text('${a.currency} · $balanceText'),
                      ],
                    ),
                  ),
                  if (!a.isSystem)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.removeAccount(a.id),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => showOnboardingAccountEditor(
            context: context,
            l10n: l10n,
            onSave: controller.addAccount,
          ),
          child: Text(l10n.onboardingAddAccount),
        ),
      ],
    );
  }

  Widget _buildCategoriesStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    OnboardingController controller,
  ) {
    final income = draft.categories
        .where((c) => c.kind == OnboardingCategoryKind.income)
        .toList();
    final expense = draft.categories
        .where((c) => c.kind == OnboardingCategoryKind.expense)
        .toList();

    Widget rowFor(OnboardingCategoryDraft c) {
      final isFixed = c.id == OnboardingDraft.kFixedExpensesCategory.id;
      final displayName = isFixed
          ? l10n.onboardingCategoryFixedExpenses
          : c.name;
      final kindLabel = c.kind == OnboardingCategoryKind.income
          ? l10n.onboardingCategoryKindIncome
          : l10n.onboardingCategoryKindExpense;
      return InkWell(
        onTap: c.isSystem
            ? null
            : () => showOnboardingCategoryEditor(
                context: context,
                l10n: l10n,
                existing: c,
                onSave: controller.upsertCategory,
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Opacity(
                  opacity: isFixed ? 0.42 : 1.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(onboardingIconForKey(c.iconKey)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(kindLabel),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isFixed)
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: l10n.onboardingFixedExpensesInfoTooltip,
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.onboardingFixedExpensesInfoTitle),
                        content: SingleChildScrollView(
                          child: Text(l10n.onboardingFixedExpensesInfoBody),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(l10n.onboardingGotIt),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (!c.isSystem)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.removeCategory(c.id),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingAddSuggested,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: Text(l10n.onboardingSuggestedSalary),
              onPressed: () => controller.addSuggestedCategory(
                id: 'salary',
                name: l10n.onboardingSuggestedSalary,
                kind: OnboardingCategoryKind.income,
                iconKey: 'work',
              ),
            ),
            ActionChip(
              label: Text(l10n.onboardingSuggestedFood),
              onPressed: () => controller.addSuggestedCategory(
                id: 'food',
                name: l10n.onboardingSuggestedFood,
                kind: OnboardingCategoryKind.expense,
                iconKey: 'restaurant',
              ),
            ),
            ActionChip(
              label: Text(l10n.onboardingSuggestedTransport),
              onPressed: () => controller.addSuggestedCategory(
                id: 'transport',
                name: l10n.onboardingSuggestedTransport,
                kind: OnboardingCategoryKind.expense,
                iconKey: 'directions_car',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingCategoriesSectionIncome,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        ...income.map(rowFor),
        const SizedBox(height: 12),
        Text(
          l10n.onboardingCategoriesSectionExpense,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        ...expense.map(rowFor),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => showOnboardingCategoryEditor(
            context: context,
            l10n: l10n,
            onSave: controller.upsertCategory,
          ),
          child: Text(l10n.onboardingAddCategory),
        ),
      ],
    );
  }

  Widget _buildRecurringStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    OnboardingController controller,
  ) {
    final incomeCats = draft.categories
        .where((c) => c.kind == OnboardingCategoryKind.income)
        .toList();
    if (incomeCats.isEmpty) {
      return Text(l10n.onboardingNoIncomeCategories);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final cat in incomeCats)
          _RecurringIncomeTile(
            category: cat,
            draft: draft,
            l10n: l10n,
            onSave: controller.setRecurring,
          ),
      ],
    );
  }

  Widget _buildBudgetsStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    OnboardingController controller,
    String localeTag,
  ) {
    _ensureBudgetControllers(draft);
    return Column(
      children: [
        for (final category in draft.categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OnboardingAmountTextField(
              key: ValueKey('budget-${category.id}'),
              controller: _budgetControllers[category.id]!,
              decoration: onboardingMoneyDecoration(
                context: context,
                labelText:
                    category.id == OnboardingDraft.kFixedExpensesCategory.id
                    ? l10n.onboardingCategoryFixedExpenses
                    : category.name,
                currencyCode: draft.profileMainCurrencyForCommit,
              ),
              onChanged: (v) {
                final minor = parseMajorToMinor(v) ?? 0;
                controller.setBudget(category.id, minor);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProjectedStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    String localeTag,
  ) {
    final m = draft.profileMainCurrencyForCommit;
    final variableSegments = <OnboardingProjectedVariableSegment>[];
    for (final c in draft.categories) {
      if (c.kind == OnboardingCategoryKind.expense &&
          c.id != OnboardingDraft.kFixedExpensesCategory.id) {
        variableSegments.add(
          OnboardingProjectedVariableSegment(
            label: c.name,
            amountMinor: draft.budgetsMinorByCategory[c.id] ?? 0,
          ),
        );
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.onboardingProjectedChartTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, inner) {
                  return OnboardingProjectedChart(
                    chartTotalHeight: inner.maxHeight,
                    expectedIncomeMinor: draft.expectedIncomeMinor,
                    fixedExpensesMinor: draft.fixedExpensesMinor,
                    variableSegments: variableSegments,
                    projectedSavingsMinor: draft.projectedSavingsMinor,
                    currencyCode: m,
                    localeTag: localeTag,
                    l10n: l10n,
                    fixedLabel: l10n.onboardingFixedExpenses,
                    savingsLabel: l10n.onboardingProjectedSavings,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.onboardingExpectedIncome}: ${formatMinorUnits(draft.expectedIncomeMinor, m, localeTag)}',
            ),
            Text(
              '${l10n.onboardingFixedExpenses}: ${formatMinorUnits(draft.fixedExpensesMinor, m, localeTag)}',
            ),
            Text(
              '${l10n.onboardingVariableExpenses}: ${formatMinorUnits(draft.variableExpensesMinor, m, localeTag)}',
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.onboardingProjectedSavings}: ${formatMinorUnits(draft.projectedSavingsMinor, m, localeTag)}',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessagingStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    OnboardingController controller,
  ) {
    final messaging = draft.messaging;
    final uid = ref.read(authUidProvider);
    final firestore = ref.read(firestoreProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (messaging.whatsAppVerified)
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF25D366),
            ),
            title: Text(l10n.onboardingVerifyWhatsApp),
          ),
        if (messaging.telegramVerified)
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF0088CC),
            ),
            title: Text(l10n.onboardingVerifyTelegram),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (uid == null) return;
            showOnboardingMessagingChannelSheet(
              context: context,
              l10n: l10n,
              channel: 'whatsapp',
              initialIdentity: _waController.text.trim(),
              firebaseUid: uid,
              firestore: firestore,
              onRequestOtp: (id) =>
                  controller.requestOtp(channel: 'whatsapp', identity: id),
              onVerify: (id, code) async {
                await controller.verifyOtp(
                  channel: 'whatsapp',
                  identity: id,
                  code: code,
                );
                _waController.text = id;
                controller.setMessaging(
                  OnboardingMessagingState(
                    whatsAppId: id,
                    whatsAppVerified: true,
                    telegramId: _tgController.text.trim().isEmpty
                        ? null
                        : _tgController.text.trim(),
                    telegramVerified: messaging.telegramVerified,
                  ),
                );
              },
            );
          },
          child: const Text('WhatsApp'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0088CC),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (uid == null) return;
            showOnboardingMessagingChannelSheet(
              context: context,
              l10n: l10n,
              channel: 'telegram',
              initialIdentity: _tgController.text.trim(),
              firebaseUid: uid,
              firestore: firestore,
              onRequestOtp: (id) =>
                  controller.requestOtp(channel: 'telegram', identity: id),
              onTelegramLinked: (id) {
                _tgController.text = id;
                controller.setMessaging(
                  OnboardingMessagingState(
                    telegramId: id,
                    telegramVerified: true,
                    whatsAppId: _waController.text.trim().isEmpty
                        ? null
                        : _waController.text.trim(),
                    whatsAppVerified: messaging.whatsAppVerified,
                  ),
                );
              },
            );
          },
          child: const Text('Telegram'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            _waController.clear();
            _tgController.clear();
            _otpController.clear();
            controller.setMessaging(const OnboardingMessagingState());
            final st = ref.read(onboardingControllerProvider);
            await _onPrimaryPressed(st, l10n);
          },
          child: Text(l10n.onboardingRemindMeLater),
        ),
      ],
    );
  }
}

class _RecurringIncomeTile extends StatefulWidget {
  const _RecurringIncomeTile({
    required this.category,
    required this.draft,
    required this.l10n,
    required this.onSave,
  });

  final OnboardingCategoryDraft category;
  final OnboardingDraft draft;
  final AppLocalizations l10n;
  final void Function(OnboardingRecurringIncomeDraft draft) onSave;

  @override
  State<_RecurringIncomeTile> createState() => _RecurringIncomeTileState();
}

class _RecurringIncomeTileState extends State<_RecurringIncomeTile> {
  late final TextEditingController _amount;
  late final TextEditingController _dayOfMonth;
  late final TextEditingController _dayOfMonthB;

  OnboardingRecurringIncomeDraft get _existing =>
      widget.draft.recurringByCategory[widget.category.id] ??
      OnboardingRecurringIncomeDraft(
        categoryId: widget.category.id,
        isRecurring: false,
      );

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _amount = TextEditingController(
      text: e.amountMinor > 0 ? formatMinorAsInputString(e.amountMinor) : '',
    );
    final days = e.daysOfMonth;
    _dayOfMonth = TextEditingController(
      text: days.isNotEmpty ? '${days[0]}' : '1',
    );
    _dayOfMonthB = TextEditingController(
      text: days.length > 1 ? '${days[1]}' : '15',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _dayOfMonth.dispose();
    _dayOfMonthB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final draft = widget.draft;
    final category = widget.category;
    final existing = _existing;
    final isOn = existing.isRecurring;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              value: isOn,
              title: Text(category.name),
              subtitle: Text(l10n.onboardingRecurringQuestion),
              onChanged: (v) {
                if (!v) {
                  widget.onSave(
                    OnboardingRecurringIncomeDraft(
                      categoryId: category.id,
                      isRecurring: false,
                    ),
                  );
                  return;
                }
                final firstAccount = draft.accounts.isNotEmpty
                    ? draft.accounts.first.id
                    : null;
                widget.onSave(
                  OnboardingRecurringIncomeDraft(
                    categoryId: category.id,
                    isRecurring: true,
                    amountMinor: 0,
                    accountId: firstAccount,
                    daysOfMonth: const [1],
                    weekday: null,
                    cadence: OnboardingCadence.monthly,
                  ),
                );
              },
            ),
            if (isOn) ...[
              OnboardingAmountTextField(
                controller: _amount,
                decoration: onboardingMoneyDecoration(
                  context: context,
                  labelText: l10n.onboardingRecurringAmountLabel,
                  currencyCode: draft.profileMainCurrencyForCommit,
                ),
                onChanged: (t) {
                  final minor = parseMajorToMinor(t) ?? 0;
                  widget.onSave(existing.copyWith(amountMinor: minor));
                },
              ),
              const SizedBox(height: 8),
              if (draft.accounts.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(
                    'acc-${existing.accountId ?? draft.accounts.first.id}',
                  ),
                  initialValue: existing.accountId ?? draft.accounts.first.id,
                  decoration: InputDecoration(
                    labelText: l10n.onboardingDepositAccountLabel,
                  ),
                  items: [
                    for (final a in draft.accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (accId) {
                    if (accId == null) return;
                    widget.onSave(existing.copyWith(accountId: accId));
                  },
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<OnboardingCadence>(
                key: ValueKey<OnboardingCadence>(existing.cadence),
                initialValue: existing.cadence,
                decoration: InputDecoration(
                  labelText: l10n.onboardingCadenceLabel,
                ),
                items: [
                  for (final c in OnboardingCadence.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(_cadenceLabel(l10n, c)),
                    ),
                ],
                onChanged: (c) {
                  if (c == null) return;
                  if (c == OnboardingCadence.weekly) {
                    final w = existing.weekday ?? DateTime.friday;
                    _dayOfMonth.text =
                        '${existing.daysOfMonth.isNotEmpty ? existing.daysOfMonth.first : 1}';
                    _dayOfMonthB.text =
                        '${existing.daysOfMonth.length > 1 ? existing.daysOfMonth[1] : 15}';
                    widget.onSave(
                      existing.copyWith(
                        cadence: c,
                        daysOfMonth: const [],
                        weekday: w,
                      ),
                    );
                  } else if (c == OnboardingCadence.biweekly) {
                    final d1 = existing.daysOfMonth.isNotEmpty
                        ? existing.daysOfMonth.first
                        : 1;
                    final d2 = existing.daysOfMonth.length > 1
                        ? existing.daysOfMonth[1]
                        : 15;
                    _dayOfMonth.text = '$d1';
                    _dayOfMonthB.text = '$d2';
                    widget.onSave(
                      existing.copyWith(
                        cadence: c,
                        daysOfMonth: [d1, d2],
                        clearWeekday: true,
                      ),
                    );
                  } else {
                    final d = existing.daysOfMonth.isNotEmpty
                        ? existing.daysOfMonth.first
                        : 1;
                    _dayOfMonth.text = '$d';
                    widget.onSave(
                      existing.copyWith(
                        cadence: c,
                        daysOfMonth: [d],
                        clearWeekday: true,
                      ),
                    );
                  }
                },
              ),
              if (existing.cadence == OnboardingCadence.monthly) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _dayOfMonth,
                  decoration: InputDecoration(
                    labelText: l10n.onboardingDayOfMonthLabel,
                    helperText: l10n.onboardingHintInvalidMonthDay,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (t) {
                    final d = int.tryParse(t) ?? 1;
                    widget.onSave(
                      existing.copyWith(daysOfMonth: [d.clamp(1, 31)]),
                    );
                  },
                ),
              ],
              if (existing.cadence == OnboardingCadence.biweekly) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dayOfMonth,
                        decoration: InputDecoration(
                          labelText: l10n.onboardingFirstPaydayLabel,
                          helperText: l10n.onboardingHintInvalidMonthDay,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (t) {
                          final d1 = int.tryParse(t) ?? 1;
                          final d2 = int.tryParse(_dayOfMonthB.text) ?? 15;
                          widget.onSave(
                            existing.copyWith(
                              daysOfMonth: [d1.clamp(1, 31), d2.clamp(1, 31)],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _dayOfMonthB,
                        decoration: InputDecoration(
                          labelText: l10n.onboardingSecondPaydayLabel,
                          helperText: l10n.onboardingHintInvalidMonthDay,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (t) {
                          final d1 = int.tryParse(_dayOfMonth.text) ?? 1;
                          final d2 = int.tryParse(t) ?? 15;
                          widget.onSave(
                            existing.copyWith(
                              daysOfMonth: [d1.clamp(1, 31), d2.clamp(1, 31)],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (existing.cadence == OnboardingCadence.weekly) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  key: ValueKey<int>(existing.weekday ?? 5),
                  initialValue: (existing.weekday ?? DateTime.friday).clamp(
                    1,
                    7,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.onboardingWeekdayLabel,
                  ),
                  items: [
                    for (var w = 1; w <= 7; w++)
                      DropdownMenuItem(
                        value: w,
                        child: Text(_narrowWeekdayLabel(context, w)),
                      ),
                  ],
                  onChanged: (w) {
                    if (w == null) return;
                    widget.onSave(existing.copyWith(weekday: w));
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TypewriterTitle extends StatefulWidget {
  const _TypewriterTitle({required this.text});

  final String text;

  @override
  State<_TypewriterTitle> createState() => _TypewriterTitleState();
}

class _TypewriterTitleState extends State<_TypewriterTitle> {
  int _visible = 0;

  @override
  void didUpdateWidget(covariant _TypewriterTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _visible = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tick();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tick();
    });
  }

  Future<void> _tick() async {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      setState(() => _visible = widget.text.length);
      return;
    }
    while (mounted && _visible < widget.text.length) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (!mounted) return;
      setState(() => _visible += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.text.substring(
      0,
      _visible.clamp(0, widget.text.length),
    );
    return Text(visible, style: Theme.of(context).textTheme.headlineSmall);
  }
}

String _titleForStep(AppLocalizations l10n, OnboardingStep step) {
  switch (step) {
    case OnboardingStep.profile:
      return l10n.onboardingStepProfileTitle;
    case OnboardingStep.accounts:
      return l10n.onboardingStepAccountsTitle;
    case OnboardingStep.categories:
      return l10n.onboardingStepCategoriesTitle;
    case OnboardingStep.recurringIncome:
      return l10n.onboardingStepRecurringTitle;
    case OnboardingStep.budgets:
      return l10n.onboardingStepBudgetsTitle;
    case OnboardingStep.projectedSavings:
      return l10n.onboardingStepProjectedTitle;
    case OnboardingStep.messaging:
      return l10n.onboardingStepMessagingTitle;
    case OnboardingStep.review:
      return l10n.onboardingStepReviewTitle;
    case OnboardingStep.commit:
      return l10n.onboardingStepCommitTitle;
    case OnboardingStep.completion:
      return l10n.onboardingStepDoneTitle;
  }
}
