import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_repository.dart';
import '../domain/messaging_otp_request_result.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_state.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingState> {
  static const int kMaxDisplayNameLength = 80;

  @override
  OnboardingState build() => OnboardingState.initial();

  void updateProfile({
    required String displayName,
    required String timezone,
    required String themePreference,
    required String locale,
    required String mainCurrency,
  }) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        displayName: displayName,
        timezone: timezone,
        themePreference: themePreference,
        locale: locale,
        mainCurrency: mainCurrency,
      ),
      clearValidation: true,
    );
  }

  /// Localized display name for the system Cash row (persisted on commit).
  void syncSystemCashDisplayName(String localizedName) {
    final accounts = state.draft.accounts.map((a) {
      if (a.id == OnboardingDraft.kSystemCashAccountId && a.isSystem) {
        return OnboardingAccountDraft(
          id: a.id,
          name: localizedName,
          type: a.type,
          currency: a.currency,
          colorArgb: a.colorArgb,
          startingBalanceMinor: a.startingBalanceMinor,
          iconKey: a.iconKey,
          isSystem: a.isSystem,
          creditLimitMinor: a.creditLimitMinor,
        );
      }
      return a;
    }).toList();
    state = state.copyWith(
      draft: state.draft.copyWith(accounts: accounts),
      clearValidation: true,
    );
  }

  /// Localized display name for the system category (Firestore row uses this text).
  void syncFixedExpensesDisplayName(String localizedName) {
    final categories = state.draft.categories.map((c) {
      if (c.id == OnboardingDraft.kFixedExpensesCategory.id) {
        return OnboardingCategoryDraft(
          id: c.id,
          name: localizedName,
          kind: c.kind,
          iconKey: c.iconKey,
          isSystem: c.isSystem,
          colorArgb: c.colorArgb,
        );
      }
      return c;
    }).toList();
    state = state.copyWith(
      draft: state.draft.copyWith(categories: categories),
      clearValidation: true,
    );
  }

  void addAccount(OnboardingAccountDraft account) {
    final next = <OnboardingAccountDraft>[...state.draft.accounts, account];
    state = state.copyWith(
      draft: state.draft.copyWith(accounts: next),
      clearValidation: true,
    );
  }

  void updateAccount(OnboardingAccountDraft updated) {
    final next = state.draft.accounts
        .map((a) => a.id == updated.id ? updated : a)
        .toList();
    state = state.copyWith(
      draft: state.draft.copyWith(accounts: next),
      clearValidation: true,
    );
  }

  void removeAccount(String accountId) {
    final match = state.draft.accounts.where((a) => a.id == accountId).toList();
    if (match.isEmpty || match.first.isSystem) return;

    final next = state.draft.accounts.where((a) => a.id != accountId).toList();
    final recurring = {...state.draft.recurringByCategory};
    for (final entry in recurring.entries.toList()) {
      if (entry.value.accountId == accountId) {
        recurring[entry.key] = OnboardingRecurringIncomeDraft(
          categoryId: entry.value.categoryId,
          isRecurring: entry.value.isRecurring,
          amountMinor: entry.value.amountMinor,
          accountId: null,
          daysOfMonth: entry.value.daysOfMonth,
          weekday: entry.value.weekday,
          cadence: entry.value.cadence,
        );
      }
    }
    state = state.copyWith(
      draft: state.draft.copyWith(
        accounts: next,
        recurringByCategory: recurring,
      ),
    );
  }

  void upsertCategory(OnboardingCategoryDraft category) {
    final copy = [...state.draft.categories];
    final idx = copy.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      copy[idx] = category;
    } else {
      copy.add(category);
    }
    final budgets = {...state.draft.budgetsMinorByCategory};
    budgets.putIfAbsent(category.id, () => 0);
    state = state.copyWith(
      draft: state.draft.copyWith(
        categories: copy,
        budgetsMinorByCategory: budgets,
      ),
      clearValidation: true,
    );
  }

  void addSuggestedCategory({
    required String id,
    required String name,
    required OnboardingCategoryKind kind,
    required String iconKey,
    int? colorArgb,
  }) {
    if (state.draft.categories.any((c) => c.id == id)) return;
    upsertCategory(
      OnboardingCategoryDraft(
        id: id,
        name: name,
        kind: kind,
        iconKey: iconKey,
        isSystem: false,
        colorArgb: colorArgb,
      ),
    );
  }

  void removeCategory(String categoryId) {
    final current = state.draft.categories;
    final category = current.firstWhere((c) => c.id == categoryId);
    if (category.isSystem) return;
    final next = current.where((c) => c.id != categoryId).toList();
    final budgets = {...state.draft.budgetsMinorByCategory}..remove(categoryId);
    final recurring = {...state.draft.recurringByCategory}..remove(categoryId);
    state = state.copyWith(
      draft: state.draft.copyWith(
        categories: next,
        budgetsMinorByCategory: budgets,
        recurringByCategory: recurring,
      ),
    );
  }

  void setRecurring(OnboardingRecurringIncomeDraft recurring) {
    final nextRecurring = {
      ...state.draft.recurringByCategory,
      recurring.categoryId: recurring,
    };
    final draft = state.draft.copyWith(recurringByCategory: nextRecurring);
    var budgets = {...draft.budgetsMinorByCategory};
    final synced = _incomeBudgetMinorFromRecurringForDraft(
      draft,
      recurring.categoryId,
    );
    if (synced != null) {
      budgets[recurring.categoryId] = synced;
    }
    state = state.copyWith(
      draft: draft.copyWith(budgetsMinorByCategory: budgets),
      clearValidation: true,
    );
  }

  /// When recurring is on with a positive amount, income category budget = monthly minor equivalent.
  static int? _incomeBudgetMinorFromRecurringForDraft(
    OnboardingDraft draft,
    String categoryId,
  ) {
    final isIncome = draft.categories.any(
      (c) => c.id == categoryId && c.kind == OnboardingCategoryKind.income,
    );
    if (!isIncome) return null;
    final r = draft.recurringByCategory[categoryId];
    if (r == null) return null;
    if (r.isRecurring && r.amountMinor > 0) {
      return _monthlyMinorFromRecurring(r);
    }
    return null;
  }

  /// Ensures every income category has a recurring draft (default: not recurring).
  void ensureRecurringDraftsForIncomeCategories() {
    state = state.copyWith(
      draft: _draftWithRecurringIncomeStepPrepared(state.draft),
      clearValidation: true,
    );
  }

  /// Ensures budget map has a key per category (defaults to 0).
  void ensureBudgetEntriesForAllCategories() {
    final budgets = {...state.draft.budgetsMinorByCategory};
    for (final c in state.draft.categories) {
      budgets.putIfAbsent(c.id, () => 0);
    }
    state = state.copyWith(
      draft: state.draft.copyWith(budgetsMinorByCategory: budgets),
      clearValidation: true,
    );
  }

  static int _monthlyMinorFromRecurring(OnboardingRecurringIncomeDraft r) {
    final base = r.amountMinor;
    return switch (r.cadence) {
      OnboardingCadence.monthly => base,
      OnboardingCadence.biweekly => base * 2,
      OnboardingCadence.weekly => base * 4,
    };
  }

  static OnboardingDraft _draftWithBudgetsStepPrepared(OnboardingDraft draft) {
    final budgets = {...draft.budgetsMinorByCategory};
    for (final c in draft.categories) {
      budgets.putIfAbsent(c.id, () => 0);
    }
    for (final c in draft.categories.where(
      (x) => x.kind == OnboardingCategoryKind.income,
    )) {
      final r = draft.recurringByCategory[c.id];
      if (r != null && r.isRecurring && r.amountMinor > 0) {
        budgets[c.id] = _monthlyMinorFromRecurring(r);
      }
    }
    return draft.copyWith(budgetsMinorByCategory: budgets);
  }

  /// Income recurring step: default recurring row per income category (single draft mutation).
  static OnboardingDraft _draftWithRecurringIncomeStepPrepared(
    OnboardingDraft draft,
  ) {
    final next = {...draft.recurringByCategory};
    for (final c in draft.categories.where(
      (x) => x.kind == OnboardingCategoryKind.income,
    )) {
      next.putIfAbsent(
        c.id,
        () => OnboardingRecurringIncomeDraft(
          categoryId: c.id,
          isRecurring: false,
        ),
      );
    }
    return draft.copyWith(recurringByCategory: next);
  }

  void setBudget(String categoryId, int amountMinor) {
    final next = {
      ...state.draft.budgetsMinorByCategory,
      categoryId: amountMinor,
    };
    state = state.copyWith(
      draft: state.draft.copyWith(budgetsMinorByCategory: next),
      clearValidation: true,
    );
  }

  void setMessaging(OnboardingMessagingState messaging) {
    state = state.copyWith(
      draft: state.draft.copyWith(messaging: messaging),
      clearValidation: true,
    );
  }

  Future<MessagingOtpRequestResult> requestOtp({
    required String channel,
    required String identity,
  }) {
    return ref
        .read(onboardingRepositoryProvider)
        .requestMessagingOtp(channel: channel, identity: identity);
  }

  Future<void> verifyOtp({
    required String channel,
    required String identity,
    required String code,
  }) async {
    await ref
        .read(onboardingRepositoryProvider)
        .verifyMessagingOtp(
          channel: channel,
          identity: identity,
          otpCode: code,
        );
  }

  void clearValidation() {
    state = state.copyWith(clearValidation: true);
  }

  void clearCommitError() {
    state = state.copyWith(clearCommitError: true);
  }

  Future<bool> next() async {
    final code = _validateStep(state.step, state.draft);
    if (code != null) {
      state = state.copyWith(validationCode: code);
      return false;
    }
    if (state.step == OnboardingStep.review) {
      return _commit();
    }
    if (state.step == OnboardingStep.commit ||
        state.step == OnboardingStep.completion) {
      return false;
    }

    final nextStep = OnboardingStep.values[state.step.index + 1];

    if (nextStep == OnboardingStep.budgets) {
      // Single state update so listeners do not see "budgets step" before seeded
      // budgets (Riverpod can notify between assignments and lock TextControllers at 0).
      state = state.copyWith(
        step: nextStep,
        draft: _draftWithBudgetsStepPrepared(state.draft),
        clearValidation: true,
      );
      return true;
    }

    if (nextStep == OnboardingStep.recurringIncome) {
      // Same rationale as budgets: step + draft in one update.
      state = state.copyWith(
        step: nextStep,
        draft: _draftWithRecurringIncomeStepPrepared(state.draft),
        clearValidation: true,
      );
      return true;
    }

    state = state.copyWith(step: nextStep, clearValidation: true);
    return true;
  }

  void back() {
    if (!state.canGoBack) return;
    state = state.copyWith(
      step: OnboardingStep.values[state.step.index - 1],
      clearValidation: true,
    );
  }

  /// Whether the user can advance from the current step (enables/disables **Next**).
  bool validateCurrentStep() => _validateStep(state.step, state.draft) == null;

  Future<bool> _commit() async {
    state = state.copyWith(
      step: OnboardingStep.commit,
      isSubmitting: true,
      clearValidation: true,
      clearCommitError: true,
    );
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .commitOnboarding(state.draft);
      state = state.copyWith(
        isSubmitting: false,
        step: OnboardingStep.completion,
        clearValidation: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        step: OnboardingStep.review,
        commitErrorMessage: e.toString(),
      );
      return false;
    }
  }

  String? _validateStep(OnboardingStep step, OnboardingDraft draft) {
    switch (step) {
      case OnboardingStep.welcome:
        return null;
      case OnboardingStep.profile:
        final name = draft.displayName.trim();
        if (name.isEmpty) return 'profileNameRequired';
        if (name.length > kMaxDisplayNameLength) return 'profileNameTooLong';
        return null;
      case OnboardingStep.accounts:
        if (draft.accounts.isEmpty) return 'accountsMinOne';
        for (final a in draft.accounts) {
          if (a.name.trim().isEmpty) return 'accountNameRequired';
        }
        return null;
      case OnboardingStep.categories:
        if (!draft.categories.any(
          (c) => c.id == OnboardingDraft.kFixedExpensesCategory.id,
        )) {
          return 'categoriesMissingFixed';
        }
        return null;
      case OnboardingStep.recurringIncome:
        for (final c in draft.categories.where(
          (x) => x.kind == OnboardingCategoryKind.income,
        )) {
          final r =
              draft.recurringByCategory[c.id] ??
              OnboardingRecurringIncomeDraft(
                categoryId: c.id,
                isRecurring: false,
              );
          if (!r.isRecurring) continue;
          if (r.amountMinor <= 0) return 'recurringAmount';
          if (r.accountId == null || r.accountId!.isEmpty) {
            return 'recurringAccount';
          }
          if (r.cadence == OnboardingCadence.weekly) {
            if (r.weekday == null || r.weekday! < 1 || r.weekday! > 7) {
              return 'recurringWeekday';
            }
            continue;
          }
          if (r.cadence == OnboardingCadence.biweekly) {
            if (r.daysOfMonth.length < 2) return 'recurringDaysTwice';
            for (final d in r.daysOfMonth) {
              if (d < 1 || d > 31) return 'recurringDayRange';
            }
            continue;
          }
          if (r.cadence == OnboardingCadence.monthly) {
            if (r.daysOfMonth.isEmpty) return 'recurringDayMonthly';
            final d = r.daysOfMonth.first;
            if (d < 1 || d > 31) return 'recurringDayRange';
            continue;
          }
        }
        return null;
      case OnboardingStep.budgets:
        for (final c in draft.categories) {
          if (!draft.budgetsMinorByCategory.containsKey(c.id)) {
            return 'budgetMissing';
          }
        }
        return null;
      case OnboardingStep.projectedSavings:
      case OnboardingStep.messaging:
      case OnboardingStep.review:
      case OnboardingStep.commit:
      case OnboardingStep.completion:
        return null;
    }
  }
}
