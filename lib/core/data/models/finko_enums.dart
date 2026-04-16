import 'package:json_annotation/json_annotation.dart';

/// Cashflow direction: amounts are always positive; direction distinguishes in/out.
enum MoneyDirection {
  @JsonValue('in')
  in_,
  @JsonValue('out')
  out_;

  static MoneyDirection? tryParse(String? raw) {
    switch (raw) {
      case 'in':
        return MoneyDirection.in_;
      case 'out':
        return MoneyDirection.out_;
      default:
        return null;
    }
  }

  String get wireName => switch (this) {
    MoneyDirection.in_ => 'in',
    MoneyDirection.out_ => 'out',
  };
}

/// [`docs/data-model.md` §4] — canonical transaction row `type` values.
///
/// The spec names **`standard`**, **`transferLeg`**, and **`adjustment`** only; the
/// table’s trailing "…" is forward compatibility, not an extra required kind today.
enum LedgerTransactionKind {
  standard,
  transferLeg,
  adjustment;

  static LedgerTransactionKind? tryParse(String? raw) {
    switch (raw) {
      case 'standard':
        return LedgerTransactionKind.standard;
      case 'transferLeg':
        return LedgerTransactionKind.transferLeg;
      case 'adjustment':
        return LedgerTransactionKind.adjustment;
      default:
        return null;
    }
  }

  String get wireName => switch (this) {
    LedgerTransactionKind.standard => 'standard',
    LedgerTransactionKind.transferLeg => 'transferLeg',
    LedgerTransactionKind.adjustment => 'adjustment',
  };
}

/// [`docs/data-model.md` §5] — canonical account types (labels live in l10n).
enum FinkoAccountType {
  checking,
  savings,
  investment,
  creditCard,
  loan,
  mortgage;

  static FinkoAccountType? tryParse(String? raw) {
    switch (raw) {
      case 'checking':
        return FinkoAccountType.checking;
      case 'savings':
        return FinkoAccountType.savings;
      case 'investment':
        return FinkoAccountType.investment;
      case 'creditCard':
        return FinkoAccountType.creditCard;
      case 'loan':
        return FinkoAccountType.loan;
      case 'mortgage':
        return FinkoAccountType.mortgage;
      default:
        return null;
    }
  }

  String get wireName => switch (this) {
    FinkoAccountType.checking => 'checking',
    FinkoAccountType.savings => 'savings',
    FinkoAccountType.investment => 'investment',
    FinkoAccountType.creditCard => 'creditCard',
    FinkoAccountType.loan => 'loan',
    FinkoAccountType.mortgage => 'mortgage',
  };
}

enum CategoryKind {
  income,
  expense;

  static CategoryKind? tryParse(String? raw) {
    switch (raw) {
      case 'income':
        return CategoryKind.income;
      case 'expense':
        return CategoryKind.expense;
      default:
        return null;
    }
  }

  String get wireName => switch (this) {
    CategoryKind.income => 'income',
    CategoryKind.expense => 'expense',
  };
}

enum ThemePreference {
  light,
  dark,
  system;

  static ThemePreference? tryParse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemePreference.light;
      case 'dark':
        return ThemePreference.dark;
      case 'system':
        return ThemePreference.system;
      default:
        return null;
    }
  }

  String get wireName => switch (this) {
    ThemePreference.light => 'light',
    ThemePreference.dark => 'dark',
    ThemePreference.system => 'system',
  };
}

enum UpcomingKind {
  standard,
  transfer;

  static UpcomingKind? tryParse(String? raw) {
    switch (raw) {
      case 'standard':
        return UpcomingKind.standard;
      case 'transfer':
        return UpcomingKind.transfer;
      default:
        return null;
    }
  }

  String get wireName => switch (this) {
    UpcomingKind.standard => 'standard',
    UpcomingKind.transfer => 'transfer',
  };
}

/// How often a [RecurringRule] posts (see `docs/data-model.md` §9).
enum RecurringCadence {
  monthly,
  twiceMonthly,
  biweekly,
  weekly;

  static RecurringCadence? tryParse(String? raw) {
    switch (raw) {
      case 'monthly':
        return RecurringCadence.monthly;
      case 'twiceMonthly':
        return RecurringCadence.twiceMonthly;
      case 'biweekly':
        return RecurringCadence.biweekly;
      case 'weekly':
        return RecurringCadence.weekly;
      default:
        return null;
    }
  }

  String get wireName => switch (this) {
    RecurringCadence.monthly => 'monthly',
    RecurringCadence.twiceMonthly => 'twiceMonthly',
    RecurringCadence.biweekly => 'biweekly',
    RecurringCadence.weekly => 'weekly',
  };
}

/// Budget row embedded under [MonthlyTotals.budgets].
enum BudgetKind {
  income,
  expense;

  static BudgetKind? tryParse(String? raw) {
    switch (raw) {
      case 'income':
        return BudgetKind.income;
      case 'expense':
        return BudgetKind.expense;
      default:
        return null;
    }
  }

  String get wireName => switch (this) {
    BudgetKind.income => 'income',
    BudgetKind.expense => 'expense',
  };
}
