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
  String get onboardingBack => 'Back';

  @override
  String get onboardingCommit => 'Finish onboarding';

  @override
  String get onboardingCompleted => 'Onboarding complete.';

  @override
  String get onboardingStepProfileTitle => 'Profile & preferences';

  @override
  String get onboardingStepAccountsTitle => 'Accounts';

  @override
  String get onboardingStepCategoriesTitle => 'Categories';

  @override
  String get onboardingStepRecurringTitle => 'Recurring income';

  @override
  String get onboardingStepBudgetsTitle => 'Budgets';

  @override
  String get onboardingStepProjectedTitle => 'Projected savings';

  @override
  String get onboardingStepMessagingTitle => 'Messaging';

  @override
  String get onboardingStepReviewTitle => 'Review & finish';

  @override
  String get onboardingReviewIntro =>
      'Check everything below. Tap finish to save your setup to Finko.';

  @override
  String get onboardingReviewPreferences => 'Your choices';

  @override
  String get onboardingReviewSectionAccounts => 'Accounts';

  @override
  String get onboardingReviewSectionCategories => 'Categories';

  @override
  String onboardingReviewCategoriesCounts(int incomeCount, int expenseCount) {
    return 'Income categories: $incomeCount · Expense categories: $expenseCount';
  }

  @override
  String get onboardingReviewSectionRecurring => 'Recurring income';

  @override
  String get onboardingReviewSectionBudgets => 'Monthly budgets';

  @override
  String get onboardingReviewSectionProjected => 'Projected monthly savings';

  @override
  String get onboardingReviewSectionMessaging => 'Messaging';

  @override
  String get onboardingReviewMessagingNone =>
      'No channels verified (you can connect later).';

  @override
  String get onboardingReviewMessagingWhatsAppOk => 'WhatsApp verified';

  @override
  String get onboardingReviewMessagingTelegramOk => 'Telegram verified';

  @override
  String get onboardingReviewRecurringOff => 'Not recurring';

  @override
  String onboardingReviewBiweeklyDays(int day1, int day2) {
    return 'Paydays: days $day1 and $day2';
  }

  @override
  String get onboardingFirstPaydayLabel => 'First payday (day of month)';

  @override
  String get onboardingSecondPaydayLabel => 'Second payday (day of month)';

  @override
  String get onboardingStepCommitTitle => 'Saving setup';

  @override
  String get onboardingStepDoneTitle => 'Done';

  @override
  String get onboardingAccountName => 'Account name';

  @override
  String get onboardingAddAccount => 'Add account';

  @override
  String get onboardingCategoryName => 'Category name';

  @override
  String get onboardingAddCategory => 'Add category';

  @override
  String get onboardingRecurringQuestion => 'Recurring on predictable dates';

  @override
  String get onboardingNoIncomeCategories => 'No income categories yet.';

  @override
  String get onboardingExpectedIncome => 'Expected income';

  @override
  String get onboardingFixedExpenses => 'Fixed expenses';

  @override
  String get onboardingVariableExpenses => 'Variable expenses';

  @override
  String get onboardingProjectedSavings => 'Projected savings';

  @override
  String get onboardingMessagingIdentity => 'Phone or Telegram username';

  @override
  String get onboardingRequestOtpWhatsApp => 'Request WhatsApp OTP';

  @override
  String get onboardingRequestOtpTelegram => 'Request Telegram OTP';

  @override
  String get onboardingOtpCode => 'OTP code';

  @override
  String get onboardingVerifyWhatsApp => 'Verify WhatsApp';

  @override
  String get onboardingVerifyTelegram => 'Verify Telegram';

  @override
  String get onboardingRemindMeLater => 'Remind me later';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingLocaleSpanishMx => 'Spanish (Mexico)';

  @override
  String get onboardingLocaleEnglishUs => 'English (US)';

  @override
  String get onboardingTimezoneMexicoSoutheast => 'Mexico — Southeast (UTC−5)';

  @override
  String get onboardingTimezoneMexicoCentral => 'Mexico — Central (UTC−6)';

  @override
  String get onboardingTimezoneMexicoPacific => 'Mexico — Pacific (UTC−7)';

  @override
  String get onboardingTimezoneMexicoNorthwest => 'Mexico — Northwest (UTC−8)';

  @override
  String get onboardingTimezoneUsPacific => 'United States — Pacific';

  @override
  String get onboardingTimezoneUsMountain => 'United States — Mountain';

  @override
  String get onboardingTimezoneUsEastern => 'United States — Eastern';

  @override
  String get onboardingCategoryFixedExpenses => 'Fixed expenses';

  @override
  String get onboardingFixedExpensesInfoTooltip => 'About fixed expenses';

  @override
  String get onboardingFixedExpensesInfoTitle => 'Why fixed expenses is locked';

  @override
  String get onboardingFixedExpensesInfoBody =>
      'This category is reserved for spending that stays about the same every month—rent, utilities, loan minimums, subscriptions, and similar obligations.\n\nIt is built into Finko so you can budget for those amounts separately from day-to-day variable spending. During onboarding it cannot be renamed or deleted; you only choose how much to budget for it in the next step.';

  @override
  String get onboardingGotIt => 'Got it';

  @override
  String get onboardingCategoryKindIncome => 'Income';

  @override
  String get onboardingCategoryKindExpense => 'Expense';

  @override
  String get onboardingPickIcon => 'Icon';

  @override
  String get onboardingSectionColor => 'Color';

  @override
  String get onboardingCadenceWeekly => 'Weekly';

  @override
  String get onboardingWeekdayLabel => 'Day of week';

  @override
  String get onboardingCategoriesSectionIncome => 'Income';

  @override
  String get onboardingCategoriesSectionExpense => 'Expense';

  @override
  String get onboardingSaveCategory => 'Save category';

  @override
  String get onboardingEditCategory => 'Edit category';

  @override
  String get onboardingProjectedChartTitle => 'How your monthly budget adds up';

  @override
  String get onboardingSuggestedSalary => 'Salary';

  @override
  String get onboardingSuggestedFood => 'Food';

  @override
  String get onboardingSuggestedTransport => 'Transport';

  @override
  String get onboardingAddSuggested => 'Add suggested';

  @override
  String get onboardingAccountTypeLabel => 'Account type';

  @override
  String get onboardingCurrencyLabel => 'Currency';

  @override
  String get onboardingStartingBalanceLabel => 'Starting balance';

  @override
  String get onboardingSaveAccount => 'Save account';

  @override
  String get onboardingEditAccount => 'Edit';

  @override
  String get onboardingRecurringAmountLabel => 'Amount (main currency)';

  @override
  String get onboardingDepositAccountLabel => 'Deposit account';

  @override
  String get onboardingCadenceLabel => 'Cadence';

  @override
  String get onboardingCadenceMonthly => 'Monthly';

  @override
  String get onboardingCadenceTwiceMonthly => 'Twice monthly';

  @override
  String get onboardingCadenceBiweekly => 'Biweekly';

  @override
  String get onboardingDayOfMonthLabel => 'Day of month (1–31)';

  @override
  String get onboardingSecondDayLabel => 'Second day (1–31)';

  @override
  String get onboardingHintInvalidMonthDay =>
      'If the day does not exist in a month, the last day of that month is used.';

  @override
  String get onboardingValidationProfileNameRequired => 'Enter a display name.';

  @override
  String get onboardingValidationProfileNameTooLong =>
      'Display name is too long.';

  @override
  String get onboardingValidationAccountsMinOne => 'Add at least one account.';

  @override
  String get onboardingValidationAccountNameRequired =>
      'Each account needs a name.';

  @override
  String get onboardingValidationCategoriesFixed =>
      'The Fixed expenses category is missing.';

  @override
  String get onboardingValidationRecurringAmount =>
      'Enter a recurring amount greater than zero.';

  @override
  String get onboardingValidationRecurringAccount =>
      'Choose a deposit account for recurring income.';

  @override
  String get onboardingValidationRecurringDaysTwice =>
      'Choose both paydays (days of the month) for biweekly income.';

  @override
  String get onboardingValidationRecurringDayMonthly =>
      'Choose a day of the month.';

  @override
  String get onboardingValidationRecurringDayRange =>
      'Use days between 1 and 31.';

  @override
  String get onboardingValidationRecurringWeekday =>
      'Choose a day of the week.';

  @override
  String get onboardingValidationBudgetMissing =>
      'Enter a budget for every category.';

  @override
  String get onboardingMessagingWhatsAppHint =>
      'WhatsApp: phone in E.164 (e.g. +525512345678)';

  @override
  String get onboardingMessagingTelegramHint => 'Telegram: @username';

  @override
  String get accountTypeLoan => 'Loan';

  @override
  String get accountTypeMortgage => 'Mortgage';

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
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginForgotPasswordMissingEmail =>
      'Enter your email above to reset your password';

  @override
  String get loginForgotPasswordSent =>
      'Password reset email sent. Check your inbox.';

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
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsThemeLabel => 'Color theme';

  @override
  String get settingsMembershipSection => 'Membership';

  @override
  String get settingsManagePlan => 'Manage your plan';

  @override
  String get settingsManagePlanSubtitle =>
      'Opens Stripe billing (coming soon).';

  @override
  String get settingsComingSoonLabel => 'Coming soon';

  @override
  String get settingsMessagingSection => 'Messaging';

  @override
  String get settingsMessagingWhatsApp => 'WhatsApp';

  @override
  String get settingsMessagingTelegram => 'Telegram';

  @override
  String get settingsMessagingStatusConnected => 'Connected';

  @override
  String get settingsMessagingStatusNotConnected => 'Not connected';

  @override
  String settingsMessagingConnectedWhatsAppDetail(String phone) {
    return 'WhatsApp number: $phone';
  }

  @override
  String settingsMessagingConnectedTelegramDetail(String username) {
    return 'Telegram: $username';
  }

  @override
  String settingsMessagingVerifiedOn(String date) {
    return 'Verified on $date';
  }

  @override
  String get settingsMessagingDisconnect => 'Disconnect';

  @override
  String get settingsMessagingDisconnectConfirmTitle =>
      'Disconnect this channel?';

  @override
  String get settingsMessagingDisconnectConfirmBody =>
      'You can reconnect anytime from Settings.';

  @override
  String get settingsMessagingDisconnectConfirmCta => 'Disconnect';

  @override
  String get settingsMessagingDisconnectCancel => 'Cancel';

  @override
  String get settingsErrorSave => 'Could not save. Try again.';

  @override
  String dashboardSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navRecurring => 'Recurring';

  @override
  String get navNewTransaction => 'New';

  @override
  String get navSpending => 'Spending';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get openShellMenu => 'Open menu';

  @override
  String get newTransactionSheetTitle => 'New transaction';

  @override
  String get newTransactionSheetBody => 'Add a movement to your ledger.';

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
  String get dashboardNetCashInfoTooltip => 'How net cash is calculated';

  @override
  String get dashboardNetCashInfoTitle => 'Net cash';

  @override
  String get dashboardNetCashInfoBody =>
      'Net cash is the sum of balances for accounts that count toward liquid cash flow.\n\nAn account is included when “Include in net cash” is turned on for that account. If that was never set, checking and credit card accounts are included by default; savings, investments, loans, and mortgages are not.\n\nFor each included account, Finko uses the balance in your main currency when available; otherwise it uses the balance in that account’s currency.';

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
  String get summaryMonthTotalLabel => 'This month';

  @override
  String get summaryRecentTransactionsLabel => 'Recent transactions';

  @override
  String get summaryNoTransactionsThisMonth => 'No transactions this month.';

  @override
  String summaryYearMonthHeading(String yearMonth) {
    return '$yearMonth';
  }

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
  String get spendingTotalSpendIn => 'Total spend in';

  @override
  String get spendingFixedExpenses => 'Fixed expenses';

  @override
  String get spendingVariableExpenses => 'Variable expenses';

  @override
  String get spendingUncategorized => 'Uncategorized';

  @override
  String get spendingStripEmpty =>
      'No periods with transactions in this range yet.';

  @override
  String spendingInPeriod(String period) {
    return 'In $period';
  }

  @override
  String get spendingTopTransactions => 'Top transactions';

  @override
  String get transactionsSearchHint => 'Search transactions';

  @override
  String get transactionsFilterAll => 'All types';

  @override
  String get transactionsFilterStandard => 'Standard';

  @override
  String get transactionsFilterTransfer => 'Transfer';

  @override
  String get transactionsFilterAdjustment => 'Adjustment';

  @override
  String get transactionsFilterSheetTitle => 'Filter by type';

  @override
  String get transactionsSearchSearchingHistory =>
      'Not found in loaded transactions. Searching full history…';

  @override
  String get transactionsSearchHistoryLimitReached =>
      'No match in the first part of your history. Try a more specific search.';

  @override
  String get transactionsSearchNoMatches => 'No matching transactions.';

  @override
  String get transactionEditorSheetEditTitle => 'Edit transaction';

  @override
  String get transactionEditorFieldDate => 'Date';

  @override
  String get transactionEditorFieldAmount => 'Amount';

  @override
  String get transactionEditorFieldDirection => 'Direction';

  @override
  String get transactionEditorDirectionIn => 'Income';

  @override
  String get transactionEditorDirectionOut => 'Expense';

  @override
  String get transactionEditorEntryTransfer => 'Transfer';

  @override
  String get transactionEditorFieldFromAccount => 'From account';

  @override
  String get transactionEditorFieldToAccount => 'To account';

  @override
  String get transactionEditorValidationFromAccount =>
      'Choose an account to move money from.';

  @override
  String get transactionEditorValidationToAccount =>
      'Choose an account to move money to.';

  @override
  String get transactionEditorValidationTransferSameCurrency =>
      'Both accounts must use the same currency for a transfer.';

  @override
  String get transactionEditorValidationTransferDistinctAccounts =>
      'Choose two different accounts.';

  @override
  String get transactionEditorFieldAccount => 'Account';

  @override
  String get transactionEditorFieldCategory => 'Category';

  @override
  String get transactionEditorCategoryNone => 'None';

  @override
  String get transactionEditorCategoryHint => 'Select a category';

  @override
  String get transactionEditorValidationCategory => 'Choose a category.';

  @override
  String get transactionEditorValidationCategoryEmpty =>
      'Add at least one category for income or expense (e.g. from the menu).';

  @override
  String get transactionEditorFieldType => 'Type';

  @override
  String get transactionEditorTypeStandard => 'Standard';

  @override
  String get transactionEditorTypeAdjustment => 'Adjustment';

  @override
  String get transactionEditorTypeTransferLeg => 'Transfer leg';

  @override
  String get transactionEditorFieldMemo => 'Memo';

  @override
  String get transactionEditorFieldTransferGroupId => 'Transfer group ID';

  @override
  String get transactionEditorFieldLinkedTransactionId =>
      'Linked transaction ID';

  @override
  String get transactionEditorSave => 'Save';

  @override
  String get transactionEditorDelete => 'Delete transaction';

  @override
  String get transactionEditorValidationAmount =>
      'Enter a valid amount greater than zero.';

  @override
  String get transactionEditorValidationAccount => 'Choose an account.';

  @override
  String get transactionEditorValidationDate =>
      'Enter a valid calendar date (YYYY-MM-DD).';

  @override
  String get transactionEditorDeleteConfirmTitle => 'Delete transaction?';

  @override
  String get transactionEditorDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get transactionEditorCancel => 'Cancel';

  @override
  String get transactionEditorDeleteConfirm => 'Delete';

  @override
  String get transactionEditorErrorSave => 'Could not save. Try again.';

  @override
  String get transactionEditorErrorDelete => 'Could not delete. Try again.';

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
  String get budgetsCategoryBudgets => 'Spending by category';

  @override
  String get budgetsBillsLeftLabel => 'Left for bills & utilities';

  @override
  String get budgetsIncomeLeftLabel => 'Left to earn';

  @override
  String get budgetsIncomeEarned => 'Earned';

  @override
  String budgetsCategorySubtitleAvailable(String amount) {
    return 'Available · $amount';
  }

  @override
  String get budgetsCompactBillsCaption => 'Left to pay';

  @override
  String get budgetsCompactEarningsCaption => 'To earn';

  @override
  String budgetsCompactAmountPaid(String amount) {
    return '$amount paid';
  }

  @override
  String budgetsCompactAmountEarned(String amount) {
    return '$amount earned';
  }

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
  String get actionRetry => 'Retry';

  @override
  String get categoriesEmpty => 'No categories yet.';

  @override
  String get accountsListSubtitle => 'Tap an account when detail routes exist.';
}
