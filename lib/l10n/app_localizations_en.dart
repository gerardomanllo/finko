// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Finko';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardHeadline => 'Your money at a glance';

  @override
  String get openSettings => 'Settings';

  @override
  String get openOnboarding => 'Onboarding';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageLabel => 'App language';

  @override
  String get localeSpanish => 'Spanish';

  @override
  String get localeEnglish => 'English';

  @override
  String get onboardingStep1Title => 'Profile & preferences';

  @override
  String get onboardingDisplayNameLabel => 'Display name';

  @override
  String get onboardingTimezoneLabel => 'Time zone';

  @override
  String get onboardingThemeLabel => 'Theme';

  @override
  String get onboardingLocaleLabel => 'Language';

  @override
  String get onboardingNext => 'Next';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String environmentBanner(String env) {
    return '[$env]';
  }

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get loginToggleSignUp => 'Need an account? Create one';

  @override
  String get loginToggleSignIn => 'Already have an account? Sign in';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String get loginMessagingNote =>
      'WhatsApp and Telegram are not sign-in methods. Connect them in Settings.';

  @override
  String get loginValidationRequired => 'This field is required';

  @override
  String get loginValidationEmail => 'Enter a valid email';

  @override
  String get loginValidationPasswordLength => 'At least 6 characters';

  @override
  String get loginErrorInvalidCredential => 'Incorrect email or password';

  @override
  String get loginErrorEmailInUse => 'This email is already registered';

  @override
  String get loginErrorGeneric => 'Sign-in could not be completed';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String dashboardSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navRecurring => 'Recurring';

  @override
  String get navSpending => 'Spending';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navMore => 'More';

  @override
  String get drawerCategories => 'Categories';

  @override
  String get drawerAccounts => 'Accounts';

  @override
  String get drawerUserPlaceholderName => 'You';

  @override
  String get drawerUserPlaceholderEmail => ' ';

  @override
  String get drawerUserPlaceholderInitial => 'F';

  @override
  String get recurringTitle => 'Recurring';

  @override
  String get spendingTitle => 'Spending';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get metricNetWorth => 'Net Worth';

  @override
  String get metricMonthlyExpense => 'Monthly expense';

  @override
  String get metricDeltaStubUp => '+2.1%';

  @override
  String get metricDeltaStubDown => '-1.0%';

  @override
  String get accountTypeChecking => 'Checking';

  @override
  String get accountTypeCreditCard => 'Credit cards';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get accountTypeInvestment => 'Investments';

  @override
  String get netCashLabel => 'Net cash';

  @override
  String get loansMortgageSectionTitle => 'Loans & mortgage';

  @override
  String get dashboardAccountsHeading => 'Accounts';

  @override
  String get dashboardUpcomingHeading => 'Upcoming';

  @override
  String get dashboardRecentHeading => 'Recent transactions';

  @override
  String get seeMore => 'See more';

  @override
  String get leftForSpending => 'Left for spending';

  @override
  String get thisMonthsBudget => 'This month’s budget';

  @override
  String get upcomingToday => 'Today';

  @override
  String get upcomingTomorrow => 'Tomorrow';

  @override
  String upcomingInDays(int count) {
    return '$count days';
  }

  @override
  String get emptyNoAccounts => 'No accounts yet.';

  @override
  String get emptyNoTransactions => 'No transactions yet.';

  @override
  String get emptyNoUpcoming => 'Nothing upcoming.';

  @override
  String get emptyNoMonthlyTotals =>
      'No monthly totals yet — add a transaction.';

  @override
  String get spendingPeriodWeek => 'Week';

  @override
  String get spendingPeriodMonth => 'Month';

  @override
  String get spendingPeriodQuarter => 'Quarter';

  @override
  String get spendingPeriodYear => 'Year';

  @override
  String get spendingIncome => 'Income';

  @override
  String get spendingExpense => 'Expense';

  @override
  String get spendingTotalSpend => 'Total spend';

  @override
  String spendingInPeriod(String period) {
    return 'In $period';
  }

  @override
  String get spendingTopTransactions => 'Top transactions';

  @override
  String get transactionsSearchHint => 'Search transactions';

  @override
  String get budgetsThisMonth => 'This month';

  @override
  String get budgetsPaceSlashDay => '/day';

  @override
  String budgetsDaysRemainingInMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: '0 days left',
    );
    return '$_temp0';
  }

  @override
  String budgetsSpendingPace(String paceWithDayUnit, String daysPhrase) {
    return '$paceWithDayUnit · $daysPhrase';
  }

  @override
  String get budgetsSpendingTitle => 'Spending';

  @override
  String get budgetsLeftToSpend => 'left to spend';

  @override
  String get budgetsSpent => 'Spent';

  @override
  String get budgetsBudgeted => 'Budgeted';

  @override
  String get budgetsBillsUtilities => 'Bills & Utilities';

  @override
  String get budgetsEarnings => 'Earnings';

  @override
  String get budgetsProjectedSavings => 'Projected savings';

  @override
  String budgetsOfTarget(String amount) {
    return 'Of $amount target';
  }

  @override
  String get budgetsCategoryBudgets => 'Category budgets';

  @override
  String get recurringThisWeek => 'This week';

  @override
  String get recurringNextWeek => 'Next week';

  @override
  String get recurringComingUp => 'Coming up';

  @override
  String get recurringDueSoon => 'Due soon';

  @override
  String get recurringComingLater => 'Coming later';

  @override
  String get categoriesEmpty => 'No categories in monthly data yet.';

  @override
  String get accountsListSubtitle => 'Tap an account when detail routes exist.';
}
