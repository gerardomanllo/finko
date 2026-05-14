import 'dart:math';

import '../../../core/data/models/user_profile.dart' show kDefaultMainCurrency;

enum OnboardingStep {
  profile,
  accounts,
  categories,
  recurringIncome,
  budgets,
  projectedSavings,
  messaging,
  review,
  commit,
  completion,
}

enum OnboardingAccountType {
  cash,
  checking,
  savings,
  investment,
  creditCard,
  loan,
  mortgage,
}

enum OnboardingCategoryKind { income, expense }

/// Monthly / biweekly use [daysOfMonth]; weekly uses [weekday] (Dart [DateTime.weekday]: Mon=1 … Sun=7).
enum OnboardingCadence { monthly, biweekly, weekly }

class OnboardingAccountDraft {
  const OnboardingAccountDraft({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.colorArgb,
    required this.startingBalanceMinor,
    required this.iconKey,
    this.isSystem = false,
    this.creditLimitMinor,
  });

  final String id;
  final String name;
  final OnboardingAccountType type;
  final String currency;
  final int colorArgb;
  final int startingBalanceMinor;

  /// Material icon key for the account avatar (user-chosen; independent of [type]).
  final String iconKey;

  /// System rows (e.g. Cash) cannot be removed.
  final bool isSystem;

  /// Total credit line for [OnboardingAccountType.creditCard] only (minor units, same [currency]).
  final int? creditLimitMinor;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'type': type.name,
    'currency': currency,
    'colorArgb': colorArgb,
    'startingBalanceMinor': startingBalanceMinor,
    'iconKey': iconKey,
    if (isSystem) 'isSystem': true,
    if (creditLimitMinor != null) 'creditLimitMinor': creditLimitMinor,
  };
}

class OnboardingCategoryDraft {
  const OnboardingCategoryDraft({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.isSystem,
    this.colorArgb,
  });

  final String id;
  final String name;
  final OnboardingCategoryKind kind;
  final String iconKey;
  final bool isSystem;

  /// Optional ARGB tint; included in `commitOnboarding` when non-null.
  final int? colorArgb;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'kind': kind.name,
    'iconKey': iconKey,
    'isSystem': isSystem,
    if (colorArgb != null) 'colorArgb': colorArgb,
  };
}

class OnboardingRecurringIncomeDraft {
  const OnboardingRecurringIncomeDraft({
    required this.categoryId,
    required this.isRecurring,
    this.amountMinor = 0,
    this.accountId,
    this.daysOfMonth = const <int>[],
    this.weekday,
    this.cadence = OnboardingCadence.monthly,
  });

  final String categoryId;
  final bool isRecurring;
  final int amountMinor;
  final String? accountId;

  /// Day-of-month anchors (1–31). Used for monthly and biweekly.
  final List<int> daysOfMonth;

  /// `DateTime.weekday` (Mon=1 … Sun=7) when [cadence] is [OnboardingCadence.weekly].
  final int? weekday;
  final OnboardingCadence cadence;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'categoryId': categoryId,
    'isRecurring': isRecurring,
    'amountMinor': amountMinor,
    'accountId': accountId,
    'daysOfMonth': daysOfMonth,
    if (weekday != null) 'weekday': weekday,
    'cadence': cadence.name,
  };

  OnboardingRecurringIncomeDraft copyWith({
    bool? isRecurring,
    int? amountMinor,
    String? accountId,
    bool clearAccountId = false,
    List<int>? daysOfMonth,
    int? weekday,
    bool clearWeekday = false,
    OnboardingCadence? cadence,
  }) {
    return OnboardingRecurringIncomeDraft(
      categoryId: categoryId,
      isRecurring: isRecurring ?? this.isRecurring,
      amountMinor: amountMinor ?? this.amountMinor,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      daysOfMonth: daysOfMonth ?? this.daysOfMonth,
      weekday: clearWeekday ? null : (weekday ?? this.weekday),
      cadence: cadence ?? this.cadence,
    );
  }
}

class OnboardingMessagingState {
  const OnboardingMessagingState({
    this.whatsAppId,
    this.telegramId,
    this.whatsAppVerified = false,
    this.telegramVerified = false,
  });

  final String? whatsAppId;
  final String? telegramId;
  final bool whatsAppVerified;
  final bool telegramVerified;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'whatsAppId': whatsAppId,
    'telegramId': telegramId,
    'whatsAppVerified': whatsAppVerified,
    'telegramVerified': telegramVerified,
  };
}

class OnboardingDraft {
  OnboardingDraft({
    this.displayName = '',
    this.timezone = 'America/Mexico_City',
    this.themePreference = 'system',
    this.locale = 'es-MX',
    this.mainCurrency = kDefaultMainCurrency,
    List<OnboardingAccountDraft>? accounts,
    List<OnboardingCategoryDraft>? categories,
    Map<String, OnboardingRecurringIncomeDraft>? recurringByCategory,
    Map<String, int>? budgetsMinorByCategory,
    OnboardingMessagingState? messaging,
    String? requestId,
  }) : accounts = accounts ?? <OnboardingAccountDraft>[kSystemCashAccountDraft],
       categories =
           categories ?? <OnboardingCategoryDraft>[kFixedExpensesCategory],
       recurringByCategory =
           recurringByCategory ?? <String, OnboardingRecurringIncomeDraft>{},
       budgetsMinorByCategory = budgetsMinorByCategory ?? <String, int>{},
       messaging = messaging ?? const OnboardingMessagingState(),
       requestId = requestId ?? _newRequestId();

  /// Deterministic id for the non-removable cash wallet row.
  static const String kSystemCashAccountId = 'cash';

  /// Default Cash row (name localized in UI via [syncSystemCashDisplayName]).
  static const OnboardingAccountDraft kSystemCashAccountDraft =
      OnboardingAccountDraft(
        id: kSystemCashAccountId,
        name: 'Cash',
        type: OnboardingAccountType.cash,
        currency: 'MXN',
        colorArgb: 0xFF689F38,
        startingBalanceMinor: 0,
        iconKey: 'payments',
        isSystem: true,
      );

  static const OnboardingCategoryDraft kFixedExpensesCategory =
      OnboardingCategoryDraft(
        id: 'fixed-expenses',
        name: 'Fixed Expenses',
        kind: OnboardingCategoryKind.expense,
        iconKey: 'lock',
        isSystem: true,
        colorArgb: 0xFF546E7A,
      );

  final String displayName;
  final String timezone;
  final String themePreference;
  final String locale;

  /// ISO 4217 main reporting currency (step 1 picker).
  final String mainCurrency;
  final List<OnboardingAccountDraft> accounts;
  final List<OnboardingCategoryDraft> categories;
  final Map<String, OnboardingRecurringIncomeDraft> recurringByCategory;
  final Map<String, int> budgetsMinorByCategory;
  final OnboardingMessagingState messaging;
  final String requestId;

  int get expectedIncomeMinor =>
      _sumBudgetsByKind(OnboardingCategoryKind.income);

  int get fixedExpensesMinor => budgetsMinorByCategory['fixed-expenses'] ?? 0;

  int get variableExpensesMinor {
    var total = 0;
    for (final category in categories) {
      if (category.kind == OnboardingCategoryKind.expense &&
          category.id != 'fixed-expenses') {
        total += budgetsMinorByCategory[category.id] ?? 0;
      }
    }
    return total;
  }

  /// Income budgets minus **all** expense budgets (fixed + variable).
  int get projectedSavingsMinor =>
      expectedIncomeMinor - totalExpenseBudgetsMinor;

  int get totalExpenseBudgetsMinor {
    var total = 0;
    for (final category in categories) {
      if (category.kind == OnboardingCategoryKind.expense) {
        total += budgetsMinorByCategory[category.id] ?? 0;
      }
    }
    return total;
  }

  /// Normalized ISO code for **`commitOnboarding`** `profile.mainCurrency`.
  String get profileMainCurrencyForCommit {
    final code = mainCurrency.trim().toUpperCase();
    return code.isEmpty ? kDefaultMainCurrency : code;
  }

  int _sumBudgetsByKind(OnboardingCategoryKind kind) {
    var total = 0;
    for (final category in categories) {
      if (category.kind == kind) {
        total += budgetsMinorByCategory[category.id] ?? 0;
      }
    }
    return total;
  }

  OnboardingDraft copyWith({
    String? displayName,
    String? timezone,
    String? themePreference,
    String? locale,
    String? mainCurrency,
    List<OnboardingAccountDraft>? accounts,
    List<OnboardingCategoryDraft>? categories,
    Map<String, OnboardingRecurringIncomeDraft>? recurringByCategory,
    Map<String, int>? budgetsMinorByCategory,
    OnboardingMessagingState? messaging,
    String? requestId,
  }) {
    return OnboardingDraft(
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      themePreference: themePreference ?? this.themePreference,
      locale: locale ?? this.locale,
      mainCurrency: mainCurrency ?? this.mainCurrency,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      recurringByCategory: recurringByCategory ?? this.recurringByCategory,
      budgetsMinorByCategory:
          budgetsMinorByCategory ?? this.budgetsMinorByCategory,
      messaging: messaging ?? this.messaging,
      requestId: requestId ?? this.requestId,
    );
  }

  Map<String, dynamic> toCommitPayload() => <String, dynamic>{
    'requestId': requestId,
    'profile': <String, dynamic>{
      'displayName': displayName.trim(),
      'timezone': timezone,
      'themePreference': themePreference,
      'locale': locale,
      'mainCurrency': profileMainCurrencyForCommit,
    },
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'categories': categories.map((c) => c.toJson()).toList(),
    'recurringIncome': recurringByCategory.values
        .map((r) => r.toJson())
        .toList(),
    'budgetsMinorByCategory': budgetsMinorByCategory,
    'messaging': messaging.toJson(),
  };
}

String _newRequestId() {
  final millis = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(1 << 31);
  return 'onb-$millis-$random';
}
