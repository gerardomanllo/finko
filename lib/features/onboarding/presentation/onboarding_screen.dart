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
import '../../../core/theme/finko_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import '../application/onboarding_state.dart';
import '../data/onboarding_timezones.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_account_editor.dart'
    show accountTypeLabel, kOnboardingCurrencies, showOnboardingAccountEditor;
import 'onboarding_account_icons.dart';
import 'onboarding_amount_field.dart';
import 'onboarding_category_editor.dart';
import 'onboarding_category_icons.dart';
import 'onboarding_input_styles.dart';
import 'onboarding_messaging_sheet.dart';
import 'onboarding_money_parsing.dart';
import 'onboarding_ui.dart';
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
        // No title here: the typewriter title in the body is the single,
        // canonical heading. Blend the bar into the page so it reads as one
        // continuous screen with no separate header.
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (state.step == OnboardingStep.welcome ||
              state.step == OnboardingStep.profile)
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
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: _StepProgressBar(step: state.step),
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      showNav ? _OnboardingNavButtons.scrollBottomInset : 24,
                    ),
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
                  if (showNav) ...[
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: const _OnboardingBottomScrim(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _OnboardingNavButtons(
                        canGoBack: state.canGoBack,
                        backLabel: l10n.onboardingBack,
                        onBack: controller.back,
                        primaryLabel: _primaryLabel(l10n, state.step),
                        primaryEnabled: !state.isSubmitting && canProceed,
                        onPrimary: () => _onPrimaryPressed(state, l10n),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _primaryLabel(AppLocalizations l10n, OnboardingStep step) {
    if (step == OnboardingStep.welcome) return l10n.onboardingWelcomeStart;
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
      case OnboardingStep.welcome:
        return _buildWelcomeStep(context, l10n);
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

  Widget _buildWelcomeStep(BuildContext context, AppLocalizations l10n) {
    final cards = <Widget>[
      _ConceptCard(
        icon: Icons.account_balance_wallet_outlined,
        accent: OnboardingAccents.accounts,
        title: l10n.onboardingWelcomeAccountsTitle,
        body: l10n.onboardingWelcomeAccountsBody,
      ),
      _ConceptCard(
        icon: Icons.swap_horiz_rounded,
        accent: OnboardingAccents.transactions,
        title: l10n.onboardingWelcomeTransactionsTitle,
        body: l10n.onboardingWelcomeTransactionsBody,
      ),
      _ConceptCard(
        icon: Icons.label_outline_rounded,
        accent: OnboardingAccents.categories,
        title: l10n.onboardingWelcomeCategoriesTitle,
        body: l10n.onboardingWelcomeCategoriesBody,
      ),
      _ConceptCard(
        icon: Icons.savings_outlined,
        accent: OnboardingAccents.budgets,
        title: l10n.onboardingWelcomeBudgetsTitle,
        body: l10n.onboardingWelcomeBudgetsBody,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _WelcomeHero(),
        const SizedBox(height: 20),
        for (var i = 0; i < cards.length; i++)
          _EntranceFade(
            // Stagger the cards in after the hero for a lively first impression.
            delayMs: 120 + i * 90,
            child: cards[i],
          ),
      ],
    );
  }

  void _commitProfile(OnboardingController controller) {
    controller.updateProfile(
      displayName: _nameController.text,
      timezone: _timezone,
      themePreference: _themeChoice,
      locale: _localeChoice,
      mainCurrency: _mainCurrency,
    );
  }

  Widget _buildProfileStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(text: l10n.onboardingProfileIntro),
        TextField(
          controller: _nameController,
          maxLength: OnboardingController.kMaxDisplayNameLength,
          decoration: InputDecoration(
            labelText: l10n.onboardingDisplayNameLabel,
          ),
          onChanged: (_) => _commitProfile(controller),
        ),
        const SizedBox(height: 8),
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
            _commitProfile(controller);
          },
        ),
        const SizedBox(height: 20),
        OnboardingToggleField(
          label: l10n.onboardingThemeLabel,
          child: OnboardingSegmentedToggle<String>(
            value: _themeChoice,
            options: [
              OnboardingToggleOption(
                'light',
                l10n.themeLight,
                Icons.light_mode_outlined,
              ),
              OnboardingToggleOption(
                'dark',
                l10n.themeDark,
                Icons.dark_mode_outlined,
              ),
              OnboardingToggleOption(
                'system',
                l10n.themeAutomatic,
                Icons.brightness_auto_outlined,
              ),
            ],
            onChanged: (v) {
              setState(() => _themeChoice = v);
              ref.read(themeModeProvider.notifier).setFromPreference(v);
              _commitProfile(controller);
            },
          ),
        ),
        const SizedBox(height: 18),
        OnboardingToggleField(
          label: l10n.onboardingLocaleLabel,
          child: OnboardingSegmentedToggle<String>(
            value: _localeChoice,
            options: [
              OnboardingToggleOption('es-MX', l10n.onboardingLocaleSpanishMx),
              OnboardingToggleOption('en-US', l10n.onboardingLocaleEnglishUs),
            ],
            onChanged: (v) async {
              setState(() => _localeChoice = v);
              await ref
                  .read(localeNotifierProvider.notifier)
                  .setLocale(localeFromBcp47(v));
              _commitProfile(controller);
            },
          ),
        ),
        const SizedBox(height: 18),
        OnboardingToggleField(
          label: l10n.onboardingMainCurrencyLabel,
          child: OnboardingSegmentedToggle<String>(
            value: _mainCurrency,
            options: [
              for (final c in kOnboardingCurrencies)
                OnboardingToggleOption(c, c),
            ],
            onChanged: (v) {
              setState(() => _mainCurrency = v);
              _commitProfile(controller);
            },
          ),
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
        _StepIntro(text: l10n.onboardingAccountsIntro),
        _AddButton(
          label: l10n.onboardingAddAccount,
          onPressed: () => showOnboardingAccountEditor(
            context: context,
            l10n: l10n,
            onSave: controller.addAccount,
          ),
        ),
        const SizedBox(height: 12),
        ...draft.accounts.map((a) {
          final balanceText = formatMinorUnits(
            a.startingBalanceMinor,
            a.currency,
            localeTag,
          );
          final displayName = a.id == OnboardingDraft.kSystemCashAccountId
              ? l10n.onboardingAccountNameCash
              : a.name;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showOnboardingAccountEditor(
                context: context,
                l10n: l10n,
                existing: a,
                onSave: controller.updateAccount,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    OnboardingIconChip(
                      icon: onboardingAccountIconForKey(a.iconKey),
                      color: Color(a.colorArgb),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${accountTypeLabel(l10n, a.type)} · ${a.currency} $balanceText',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoriesStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    OnboardingController controller,
  ) {
    final sorted = onboardingCategoriesForDisplay(draft.categories);
    final income = sorted
        .where((c) => c.kind == OnboardingCategoryKind.income)
        .toList();
    final expense = sorted
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
      final chipColor = c.colorArgb != null
          ? Color(c.colorArgb!)
          : (c.kind == OnboardingCategoryKind.income
                ? FinkoColors.income
                : OnboardingAccents.categories);
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: c.isSystem
              ? null
              : () => showOnboardingCategoryEditor(
                  context: context,
                  l10n: l10n,
                  existing: c,
                  onSave: controller.upsertCategory,
                ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: isFixed ? 0.55 : 1.0,
                    child: Row(
                      children: [
                        OnboardingIconChip(
                          icon: onboardingIconForKey(c.iconKey),
                          color: chipColor,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                kindLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
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
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(text: l10n.onboardingCategoriesIntro),
        Text(
          l10n.onboardingAddSuggested,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SuggestedChip(
              icon: Icons.work_outline_rounded,
              accent: FinkoColors.income,
              label: l10n.onboardingSuggestedSalary,
              onPressed: () => controller.addSuggestedCategory(
                id: 'salary',
                name: l10n.onboardingSuggestedSalary,
                kind: OnboardingCategoryKind.income,
                iconKey: 'work',
              ),
            ),
            _SuggestedChip(
              icon: Icons.restaurant_rounded,
              accent: OnboardingAccents.budgets,
              label: l10n.onboardingSuggestedFood,
              onPressed: () => controller.addSuggestedCategory(
                id: 'food',
                name: l10n.onboardingSuggestedFood,
                kind: OnboardingCategoryKind.expense,
                iconKey: 'restaurant',
              ),
            ),
            _SuggestedChip(
              icon: Icons.directions_car_rounded,
              accent: OnboardingAccents.transactions,
              label: l10n.onboardingSuggestedTransport,
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
        _AddButton(
          label: l10n.onboardingAddCategory,
          onPressed: () => showOnboardingCategoryEditor(
            context: context,
            l10n: l10n,
            onSave: controller.upsertCategory,
          ),
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
      ],
    );
  }

  Widget _buildRecurringStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    OnboardingController controller,
  ) {
    final incomeCats = onboardingCategoriesForDisplay(
      draft.categories,
    ).where((c) => c.kind == OnboardingCategoryKind.income).toList();
    if (incomeCats.isEmpty) {
      return Text(l10n.onboardingNoIncomeCategories);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(text: l10n.onboardingRecurringIntro),
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
    final sorted = onboardingCategoriesForDisplay(draft.categories);
    final income = sorted
        .where((c) => c.kind == OnboardingCategoryKind.income)
        .toList();
    final expense = sorted
        .where((c) => c.kind == OnboardingCategoryKind.expense)
        .toList();

    Widget cardFor(OnboardingCategoryDraft category) {
      final isFixed = category.id == OnboardingDraft.kFixedExpensesCategory.id;
      final displayName = isFixed
          ? l10n.onboardingCategoryFixedExpenses
          : category.name;
      final isIncome = category.kind == OnboardingCategoryKind.income;
      final accent = isIncome ? FinkoColors.income : OnboardingAccents.budgets;
      final chipColor = category.colorArgb != null
          ? Color(category.colorArgb!)
          : accent;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingIconChip(
                icon: onboardingIconForKey(category.iconKey),
                color: chipColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        OnboardingKindBadge(
                          label: isIncome
                              ? l10n.onboardingCategoryKindIncomeShort
                              : l10n.onboardingCategoryKindExpenseShort,
                          accent: accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OnboardingAmountTextField(
                      key: ValueKey('budget-${category.id}'),
                      controller: _budgetControllers[category.id]!,
                      decoration: onboardingMoneyDecoration(
                        context: context,
                        labelText: l10n.onboardingBudgetAmountLabel,
                        currencyCode: draft.profileMainCurrencyForCommit,
                      ),
                      onChanged: (v) {
                        final minor = parseMajorToMinor(v) ?? 0;
                        controller.setBudget(category.id, minor);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(text: l10n.onboardingBudgetsIntro),
        if (income.isNotEmpty) ...[
          Text(
            l10n.onboardingCategoriesSectionIncome,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...income.map(cardFor),
          const SizedBox(height: 8),
        ],
        if (expense.isNotEmpty) ...[
          Text(
            l10n.onboardingCategoriesSectionExpense,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...expense.map(cardFor),
        ],
      ],
    );
  }

  static const double _kProjectedChartHeight = 280;

  Widget _buildProjectedStep(
    BuildContext context,
    AppLocalizations l10n,
    OnboardingDraft draft,
    String localeTag,
  ) {
    final m = draft.profileMainCurrencyForCommit;
    final savings = draft.projectedSavingsMinor;
    final savingsColor = savings > 0
        ? FinkoColors.income
        : savings < 0
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final savingsFormatted = formatMinorUnits(savings.abs(), m, localeTag);
    final heroCaption = savings > 0
        ? l10n.onboardingProjectedHeroPositive
        : savings < 0
        ? l10n.onboardingProjectedHeroNegative
        : l10n.onboardingProjectedHeroZero;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepIntro(text: l10n.onboardingProjectedIntro),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                savingsColor.withValues(alpha: 0.14),
                savingsColor.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: savingsColor.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heroCaption,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                savingsFormatted,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: savingsColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.onboardingProjectedSavings,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: savingsColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OnboardingMetricTile(
                label: l10n.onboardingExpectedIncome,
                value: formatMinorUnits(
                  draft.expectedIncomeMinor,
                  m,
                  localeTag,
                ),
                accent: FinkoColors.income,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OnboardingMetricTile(
                label: l10n.onboardingFixedExpenses,
                value: formatMinorUnits(draft.fixedExpensesMinor, m, localeTag),
                accent: FinkoColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OnboardingMetricTile(
          label: l10n.onboardingVariableExpenses,
          value: formatMinorUnits(draft.variableExpensesMinor, m, localeTag),
          accent: OnboardingAccents.categories,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingProjectedChartTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
            child: SizedBox(
              height: _kProjectedChartHeight,
              child: OnboardingProjectedChart(
                chartTotalHeight: _kProjectedChartHeight,
                expectedIncomeMinor: draft.expectedIncomeMinor,
                fixedExpensesMinor: draft.fixedExpensesMinor,
                variableSegments: variableSegments,
                projectedSavingsMinor: draft.projectedSavingsMinor,
                currencyCode: m,
                localeTag: localeTag,
                l10n: l10n,
                fixedLabel: l10n.onboardingFixedExpenses,
                savingsLabel: l10n.onboardingProjectedSavings,
              ),
            ),
          ),
        ),
      ],
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
        _StepIntro(text: l10n.onboardingMessagingIntro),
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
    final chipColor = category.colorArgb != null
        ? Color(category.colorArgb!)
        : OnboardingAccents.income;

    String accountLabel(String id) {
      final a = draft.accounts.where((x) => x.id == id).firstOrNull;
      if (a == null) return id;
      if (a.id == OnboardingDraft.kSystemCashAccountId) {
        return l10n.onboardingAccountNameCash;
      }
      return a.name;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingIconChip(
                  icon: onboardingIconForKey(category.iconKey),
                  color: chipColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.onboardingRecurringQuestion,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OnboardingSegmentedToggle<bool>(
              value: isOn,
              options: [
                OnboardingToggleOption(
                  false,
                  l10n.onboardingRecurringNo,
                  Icons.shuffle_rounded,
                ),
                OnboardingToggleOption(
                  true,
                  l10n.onboardingRecurringYes,
                  Icons.event_repeat_rounded,
                ),
              ],
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: OnboardingAccents.income.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: OnboardingAccents.income.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.onboardingRecurringDetailsLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 14),
                    if (draft.accounts.isNotEmpty) ...[
                      Text(
                        l10n.onboardingDepositAccountLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in draft.accounts)
                            OnboardingChoiceChip(
                              label: accountLabel(a.id),
                              selected:
                                  (existing.accountId ??
                                      draft.accounts.first.id) ==
                                  a.id,
                              accent: OnboardingAccents.accounts,
                              onSelected: (_) => widget.onSave(
                                existing.copyWith(accountId: a.id),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      l10n.onboardingCadenceLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    OnboardingSegmentedToggle<OnboardingCadence>(
                      value: existing.cadence,
                      options: [
                        for (final c in OnboardingCadence.values)
                          OnboardingToggleOption(c, _cadenceLabel(l10n, c)),
                      ],
                      onChanged: (c) {
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dayOfMonth,
                        decoration: InputDecoration(
                          labelText: l10n.onboardingDayOfMonthLabel,
                          helperText: l10n.onboardingHintInvalidMonthDay,
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
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
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dayOfMonth,
                              decoration: InputDecoration(
                                labelText: l10n.onboardingFirstPaydayLabel,
                                helperText: l10n.onboardingHintInvalidMonthDay,
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (t) {
                                final d1 = int.tryParse(t) ?? 1;
                                final d2 =
                                    int.tryParse(_dayOfMonthB.text) ?? 15;
                                widget.onSave(
                                  existing.copyWith(
                                    daysOfMonth: [
                                      d1.clamp(1, 31),
                                      d2.clamp(1, 31),
                                    ],
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
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (t) {
                                final d1 = int.tryParse(_dayOfMonth.text) ?? 1;
                                final d2 = int.tryParse(t) ?? 15;
                                widget.onSave(
                                  existing.copyWith(
                                    daysOfMonth: [
                                      d1.clamp(1, 31),
                                      d2.clamp(1, 31),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (existing.cadence == OnboardingCadence.weekly) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.onboardingWeekdayLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var w = 1; w <= 7; w++)
                            OnboardingChoiceChip(
                              label: _narrowWeekdayLabel(context, w),
                              selected:
                                  (existing.weekday ?? DateTime.friday) == w,
                              accent: OnboardingAccents.income,
                              onSelected: (_) =>
                                  widget.onSave(existing.copyWith(weekday: w)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                l10n.onboardingRecurringSkipHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Friendly gradient banner shown at the top of the welcome step.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FinkoColors.primaryLight, FinkoColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: FinkoColors.primary.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.onboardingWelcomeHeadline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingWelcomeIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Short explanatory tip shown at the top of a collection step so the user
/// understands what the step is for before being asked to fill it in.
class _StepIntro extends StatelessWidget {
  const _StepIntro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single concept explainer used on the welcome/overview step.
class _ConceptCard extends StatelessWidget {
  const _ConceptCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingIconChip(icon: icon, color: accent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary "add" affordance — a clearly-visible tinted, dashed-feel button
/// that reads as secondary to the primary CTA (and never white-on-white).
class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: accent,
          backgroundColor: accent.withValues(alpha: 0.10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

/// Playful tinted suggestion chip with a leading colored icon.
class _SuggestedChip extends StatelessWidget {
  const _SuggestedChip({
    required this.icon,
    required this.accent,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: accent),
      label: Text(label),
      backgroundColor: accent.withValues(alpha: 0.10),
      side: BorderSide(color: accent.withValues(alpha: 0.32)),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      shape: const StadiumBorder(),
      onPressed: onPressed,
    );
  }
}

/// A single continuous progress bar. It conveys "how far along" without
/// revealing the number of steps, and animates smoothly as the user advances.
class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    // User-facing steps run from welcome through review (commit/completion are
    // internal), so the bar fills to 100% at review.
    final total = OnboardingStep.review.index + 1;
    final fraction = ((step.index + 1) / total).clamp(0.0, 1.0);
    final accent = Theme.of(context).colorScheme.primary;
    final track = accent.withValues(alpha: 0.12);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        color: track,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          alignment: Alignment.centerLeft,
          widthFactor: fraction,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [FinkoColors.primaryLight, FinkoColors.primary],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen-edge scrim: fades from transparent (top) to scaffold color at the bottom.
class _OnboardingBottomScrim extends StatelessWidget {
  const _OnboardingBottomScrim();

  /// How far the fade rises from the physical bottom of the step area.
  static const double height = 120;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg.withValues(alpha: 0), bg.withValues(alpha: 0.65), bg],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Back / primary actions pinned to the screen bottom (no background of its own).
class _OnboardingNavButtons extends StatelessWidget {
  const _OnboardingNavButtons({
    required this.canGoBack,
    required this.backLabel,
    required this.onBack,
    required this.primaryLabel,
    required this.primaryEnabled,
    required this.onPrimary,
  });

  /// Minimal scroll padding so the last row can clear the button bar.
  static const double scrollBottomInset = 80;

  final bool canGoBack;
  final String backLabel;
  final VoidCallback onBack;
  final String primaryLabel;
  final bool primaryEnabled;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          if (canGoBack)
            OutlinedButton(onPressed: onBack, child: Text(backLabel)),
          const Spacer(),
          FilledButton(
            onPressed: primaryEnabled ? onPrimary : null,
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}

/// Lightweight fade + slide-up entrance, used to stagger the welcome cards.
/// Honors the platform "reduce motion" setting.
class _EntranceFade extends StatefulWidget {
  const _EntranceFade({required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduced) {
        if (mounted) setState(() => _shown = true);
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: widget.delayMs));
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        child: widget.child,
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
    case OnboardingStep.welcome:
      return l10n.onboardingStepWelcomeTitle;
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
