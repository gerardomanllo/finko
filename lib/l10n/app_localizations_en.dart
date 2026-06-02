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
  String get onboardingMainCurrencyLabel => 'Main currency';

  @override
  String get onboardingAccountNameCash => 'Cash';

  @override
  String get onboardingCreditLimitLabel => 'Total credit line';

  @override
  String onboardingProjectedSegmentLine(
    String name,
    String percent,
    String amount,
  ) {
    return '$name $percent% - $amount';
  }

  @override
  String onboardingProjectedOverspendLine(String amount) {
    return 'NO SAVINGS - $amount OVER INCOME';
  }

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingCommit => 'Finish onboarding';

  @override
  String get onboardingCompleted => 'Onboarding complete.';

  @override
  String get onboardingStepWelcomeTitle => 'Welcome to Finko';

  @override
  String get onboardingWelcomeStart => 'Get started';

  @override
  String get onboardingWelcomeHeadline => 'Hi! Here\'s how Finko works.';

  @override
  String get onboardingWelcomeIntro =>
      'Finko follows how your money really works: it lives in accounts, moves with every transaction, gets grouped into categories, and budgets help you plan ahead. That\'s the whole idea.';

  @override
  String get onboardingWelcomeAccountsTitle => 'Accounts';

  @override
  String get onboardingWelcomeAccountsBody =>
      'These are the places your money lives—your bank account, cash, credit cards. Finko keeps them all in one place.';

  @override
  String get onboardingWelcomeTransactionsTitle => 'Transactions';

  @override
  String get onboardingWelcomeTransactionsBody =>
      'Every time money comes in or goes out, that\'s a transaction. Logging them keeps your balances up to date—no spreadsheet required.';

  @override
  String get onboardingWelcomeCategoriesTitle => 'Categories';

  @override
  String get onboardingWelcomeCategoriesBody =>
      'Categories tell you what your money was for—groceries, rent, fun. An account is where your money is; a category is what it\'s for.';

  @override
  String get onboardingWelcomeBudgetsTitle => 'Budgets';

  @override
  String get onboardingWelcomeBudgetsBody =>
      'A budget is a plan, not a rule. It shows you where to adjust—it\'s not about winning or losing.';

  @override
  String get onboardingProfileIntro =>
      'Let\'s start with the basics to set up your experience.';

  @override
  String get onboardingAccountsIntro =>
      'Add each place you keep money—bank, cash, cards. Don\'t worry about being exact; you can edit anytime.';

  @override
  String get onboardingCategoriesIntro =>
      'Categories group your money by purpose. Remember: an account is where your money is; a category is what it\'s for.';

  @override
  String get onboardingRecurringIntro =>
      'Do you have income that arrives regularly? Telling us when and how much lets Finko project your months.';

  @override
  String get onboardingRecurringYes => 'Yes, regular';

  @override
  String get onboardingRecurringNo => 'No, varies';

  @override
  String get onboardingRecurringDetailsLabel => 'Payment details';

  @override
  String get onboardingRecurringSkipHint =>
      'You can still set an expected amount on the budgets step.';

  @override
  String get onboardingProjectedHeroPositive => 'You could save each month';

  @override
  String get onboardingProjectedHeroNegative => 'Over budget by';

  @override
  String get onboardingProjectedHeroZero => 'Break even — no room to save';

  @override
  String get onboardingBudgetsIntro =>
      'Set gentle targets for a few categories. Going over just tells you where to adjust—you can\'t \"fail\".';

  @override
  String get onboardingProjectedIntro =>
      'This is a forecast based on what you just entered, not a promise. It shows where you might land each month.';

  @override
  String get onboardingMessagingIntro =>
      'Connect WhatsApp or Telegram to log transactions with a quick message. It\'s optional—you can do this later.';

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
  String onboardingReviewRecurringMonthly(
    String category,
    String amount,
    String day,
  ) {
    return '$category: $amount monthly, paid on the $day of each month';
  }

  @override
  String onboardingReviewRecurringBiweekly(
    String category,
    String amount,
    String day1,
    String day2,
  ) {
    return '$category: $amount paid on the $day1 and $day2 of each month';
  }

  @override
  String onboardingReviewRecurringWeekly(
    String category,
    String amount,
    String weekday,
  ) {
    return '$category: $amount every $weekday';
  }

  @override
  String onboardingReviewRecurringVariable(String category) {
    return '$category: variable income with no fixed pay date';
  }

  @override
  String get onboardingCategoryKindIncomeShort => 'Income';

  @override
  String get onboardingCategoryKindExpenseShort => 'Expense';

  @override
  String get onboardingBudgetAmountLabel => 'Monthly target';

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
  String get onboardingRequestOtpTelegram => 'Link Telegram';

  @override
  String get onboardingOtpCode => 'OTP code';

  @override
  String get messagingTelegramLinkInstructions =>
      'Open the Finko bot in Telegram from the app, tap Start, then tap Done here when the app shows Telegram as linked.';

  @override
  String get messagingTelegramOpenBot => 'Open Telegram';

  @override
  String messagingOtpDevCodeSnack(String code) {
    return 'Dev build: your OTP is $code';
  }

  @override
  String get messagingTelegramIntro =>
      'Link your Telegram account for Finko. Choose phone (international format) or your Telegram @username, then follow the steps.';

  @override
  String get messagingTelegramLinkMethodLabel =>
      'How should we refer to your Telegram account?';

  @override
  String get messagingTelegramLinkMethodPhone => 'Phone';

  @override
  String get messagingTelegramLinkMethodUsername => 'Username';

  @override
  String get messagingTelegramCountryCodeLabel => 'Country code';

  @override
  String get messagingTelegramPhoneLabel => 'Phone number';

  @override
  String get messagingTelegramPhoneHint => 'Digits only (no spaces)';

  @override
  String get messagingTelegramUsernameLabel => 'Telegram username';

  @override
  String get messagingTelegramNext => 'Next';

  @override
  String get messagingTelegramStatusRegistering =>
      'Registering phone / username with Finko…';

  @override
  String get messagingTelegramStatusPreparingTelegram =>
      'Preparing secure link for Telegram…';

  @override
  String get messagingTelegramStatusWaitingForBot =>
      'Waiting for you to open Telegram and tap Start on the Finko bot…';

  @override
  String get messagingTelegramAwaitingBotBody =>
      'We will detect the link automatically. If nothing happens after you tap Start, return here and confirm your country code and number (or username) are correct.';

  @override
  String get messagingTelegramListeningFirestore =>
      'Listening to your Firestore link document for chat_id…';

  @override
  String get messagingTelegramStatusLinkDetected =>
      'Telegram chat linked successfully.';

  @override
  String get messagingTelegramLinkedTitle => 'Linked';

  @override
  String get messagingTelegramLinkedBody =>
      'Your Telegram account is connected to Finko. Tap Done to continue, or close and finish later.';

  @override
  String get messagingTelegramDone => 'Done';

  @override
  String get messagingTelegramClose => 'Close';

  @override
  String get messagingTelegramPreparingHint =>
      'Talking to Cloud Functions and Firestore. In debug builds, see the trace panel below.';

  @override
  String get messagingTelegramLinkFailedTitle => 'Something went wrong';

  @override
  String get messagingTelegramRetry => 'Try again';

  @override
  String get messagingTelegramErrPhoneTooShort =>
      'Enter more digits for your phone number.';

  @override
  String get messagingTelegramErrPhoneFormat =>
      'That phone number does not look like a valid international number (+country…).';

  @override
  String get messagingTelegramErrUsernameTooShort =>
      'Enter a valid Telegram username (at least 5 characters after @).';

  @override
  String get messagingTelegramErrStepServer => 'Server configuration';

  @override
  String get messagingTelegramErrNoDeepLink =>
      'The app did not receive a Telegram deep link. Check TELEGRAM_BOT_USERNAME and function deploy.';

  @override
  String get messagingTelegramErrUnexpectedResponse =>
      'Unexpected server response. Try again or update the app.';

  @override
  String get messagingTelegramErrStepTimeout =>
      'Timed out waiting for Telegram';

  @override
  String get messagingTelegramTimeoutBody =>
      'Open Telegram from the button, tap Start on the bot, and try again. Tokens expire after a few minutes.';

  @override
  String get messagingTelegramErrStepCallable => 'Cloud Function error';

  @override
  String get messagingTelegramErrStepFirestore => 'Firestore listener error';

  @override
  String get messagingTelegramErrStepUnknown => 'Unexpected error';

  @override
  String get messagingTelegramErrLaunchTelegram =>
      'Could not open Telegram from this device.';

  @override
  String get messagingTelegramErrStillNeedsBot =>
      'The server still asks to open the bot. Tap Start in Telegram, then tap Continue again.';

  @override
  String get messagingTelegramErrVerify => 'Verification failed';

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
  String get onboardingValidationCategoriesExpense =>
      'Add at least one expense category.';

  @override
  String get onboardingBudgetsFixedExpenseHint =>
      'Rent, loans, subscriptions, and similar monthly costs.';

  @override
  String get categoryFixedExpenseToggle => 'Fixed expense';

  @override
  String get categoryFixedExpenseToggleHint =>
      'Counts toward fixed vs variable spending and your fixed-expenses budget card.';

  @override
  String get accountsNeedExpenseCategory =>
      'Add an expense category before setting a non-zero starting balance.';

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
  String get themeAutomatic => 'Automatic';

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
  String get loginErrorGoogleConfig =>
      'Google sign-in is not configured for this build. Use the matching dev/prod flavor and check Firebase OAuth setup.';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete my account';

  @override
  String get settingsDeleteAccountDialog1Title => 'Delete your account?';

  @override
  String get settingsDeleteAccountDialog1Body =>
      'This will permanently remove your Finko profile, ledger data, and messaging integrations. You cannot undo this.';

  @override
  String get settingsDeleteAccountDialog2Title => 'Are you sure?';

  @override
  String get settingsDeleteAccountDialog2Body =>
      'All transactions, accounts, categories, and backups tied to this account will be erased from our servers.';

  @override
  String get settingsDeleteAccountDialog3Title => 'Final confirmation';

  @override
  String get settingsDeleteAccountDialog3Body =>
      'Your Firebase sign-in will be deleted and you will lose access immediately. Tap only if you intend to leave Finko forever.';

  @override
  String get settingsDeleteAccountContinue => 'Continue';

  @override
  String get settingsDeleteAccountCancel => 'Cancel';

  @override
  String get settingsDeleteAccountConfirmDelete => 'Delete my account';

  @override
  String get settingsDeleteAccountDeleting => 'Deleting account…';

  @override
  String get settingsDeleteAccountError =>
      'Could not delete account. Try again or contact support.';

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
  String get settingsMessagingTelegramBotDefaults => 'Bot defaults';

  @override
  String get settingsTelegramBotDefaultsTitle => 'Telegram bot defaults';

  @override
  String get settingsTelegramBotDefaultsSubtitle =>
      'Optional shortcuts used when you chat with the Finko bot (account, categories, reply language).';

  @override
  String get settingsTelegramBotDefaultsLocale => 'Bot language';

  @override
  String get settingsTelegramBotDefaultsLocaleFollow => 'Match Telegram';

  @override
  String get settingsTelegramBotDefaultsLocaleEs => 'Spanish';

  @override
  String get settingsTelegramBotDefaultsLocaleEn => 'English';

  @override
  String get settingsTelegramBotDefaultsAccount => 'Default account';

  @override
  String get settingsTelegramBotDefaultsExpenseCategory =>
      'Default expense category';

  @override
  String get settingsTelegramBotDefaultsIncomeCategory =>
      'Default income category';

  @override
  String get settingsTelegramBotDefaultsNone => 'None';

  @override
  String get settingsTelegramBotDefaultsSave => 'Save';

  @override
  String get settingsTelegramBotDefaultsClear => 'Clear defaults';

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
  String get drawerPlanFree => 'Free plan';

  @override
  String get drawerStatsIncomeLabel => 'Income';

  @override
  String get drawerStatsExpenseLabel => 'Expenses';

  @override
  String get drawerStatsSavingsLabel => 'Savings';

  @override
  String get drawerNavSectionTitle => 'Menu';

  @override
  String get drawerNetWorthDeltaStub => '+2.1% this month';

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
  String get categoryEditorDeleteCategory => 'Delete category…';

  @override
  String get categoryEditorMonthlyBudgetLabel =>
      'Monthly budget (main currency)';

  @override
  String get accountEditorDeleteAccount => 'Delete account…';

  @override
  String categoryDeleteCascadeTitle(String name) {
    return 'Delete “$name” and all related data?';
  }

  @override
  String categoryDeleteCascadeBody(
    int transactions,
    int recurring,
    int upcoming,
  ) {
    return 'This removes $transactions transactions, $recurring recurring rules, $upcoming upcoming items, and this category’s budget row. This cannot be undone.';
  }

  @override
  String accountDeleteCascadeTitle(String name) {
    return 'Delete account “$name” and all related data?';
  }

  @override
  String accountDeleteCascadeBody(
    int transactions,
    int recurring,
    int upcoming,
  ) {
    return 'This removes $transactions transactions (including paired transfer legs), $recurring recurring rows, $upcoming upcoming items, then the account. This cannot be undone.';
  }

  @override
  String get deleteCascadeConfirm => 'Delete everything';

  @override
  String get deleteCascadeSuccess => 'Deleted.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get metricNetWorth => 'Net Worth';

  @override
  String get metricNetWorthSeeAccountsFooter => 'See my accounts';

  @override
  String get metricMonthlyExpenseSeeSpendingFooter => 'See my spending';

  @override
  String get metricMonthlyExpense => 'Monthly expense';

  @override
  String get metricDeltaStubUp => '+2.1%';

  @override
  String get metricDeltaStubDown => '-1.0%';

  @override
  String get accountTypeChecking => 'Checking';

  @override
  String get accountTypeCash => 'Cash';

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
      'Net cash is a signed total for accounts that count toward liquid cash flow: balances on asset accounts (such as checking) are added, and amounts owed on liability accounts (such as credit cards) are subtracted.\n\nAn account is included when “Include in net cash” is turned on for that account. If that was never set, checking and credit card accounts are included by default; savings, investments, loans, and mortgages are not.\n\nFor each included account, Finko uses the balance in your main currency when available; otherwise it uses the balance in that account’s currency.';

  @override
  String get loansMortgageSectionTitle => 'Loans & mortgage';

  @override
  String get dashboardAccountsHeading => 'Accounts';

  @override
  String get dashboardUpcomingHeading => 'Upcoming';

  @override
  String get dashboardUpcomingSeeAll => 'See all upcoming';

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
  String get transactionEditorFieldTransferAmountOut => 'Amount sent';

  @override
  String get transactionEditorFieldTransferAmountIn => 'Amount received';

  @override
  String get transactionEditorFieldDirection => 'Direction';

  @override
  String get transactionEditorDirectionIn => 'Income';

  @override
  String get transactionEditorDirectionOut => 'Expense';

  @override
  String get transactionEditorEntryTransfer => 'Transfer';

  @override
  String get transactionEditorModeRecurring => 'Recurring';

  @override
  String get newTransactionRecurringHint =>
      'Saves this entry, then you pick how often it repeats. You can cancel the schedule and keep only this one movement.';

  @override
  String get transactionEditorSaveAndMakeRecurring => 'Save & make recurring';

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
  String get transactionEditorMakeRecurring => 'Make recurring';

  @override
  String get recurringFromTxTitle => 'Create recurring rule';

  @override
  String get recurringFromTxCadence => 'How often';

  @override
  String get recurringFromTxCadenceMonthly => 'Monthly';

  @override
  String get recurringFromTxCadenceTwiceMonthly => 'Twice a month';

  @override
  String get recurringFromTxCadenceBiweekly => 'Every two weeks';

  @override
  String get recurringFromTxCadenceWeekly => 'Weekly';

  @override
  String get recurringFromTxDayOfMonth => 'Day of month (1–31)';

  @override
  String get recurringFromTxSecondDay => 'Second day (1–31)';

  @override
  String get recurringFromTxWeekday => 'Weekday';

  @override
  String get recurringFromTxSubmit => 'Create rule';

  @override
  String get recurringFromTxSuccess => 'Recurring rule created.';

  @override
  String get recurringFromTxError => 'Could not create recurring rule.';

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
  String get budgetsBillsUtilities => 'Fixed expenses';

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
  String get budgetsBillsLeftLabel => 'Left for fixed expenses';

  @override
  String get budgetsIncomeLeftLabel => 'Left to earn';

  @override
  String get budgetsIncomeEarned => 'Earned';

  @override
  String budgetsCategorySubtitleRemaining(String amount) {
    return '$amount available';
  }

  @override
  String budgetsCategorySubtitleOver(String amount) {
    return '$amount over';
  }

  @override
  String get budgetsCategoryOverBudgetTooltip =>
      'Spending is over this category’s budget';

  @override
  String get budgetsCompactBillsCaption => 'Paid toward fixed';

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
  String get categoriesAddCategory => 'Add category';

  @override
  String get accountsAddAccount => 'Add account';

  @override
  String get accountsListSubtitle => 'Tap an account when detail routes exist.';

  @override
  String get agentTitle => 'Agent';

  @override
  String get agentEntryPillLabel => 'Agent';

  @override
  String get agentBackToDashboard => 'Dashboard';

  @override
  String get agentComposerHint => 'Message your agent…';

  @override
  String get agentAttachImage => 'Attach image';

  @override
  String get agentRecordVoice => 'Record voice';

  @override
  String get agentSend => 'Send';

  @override
  String get agentDismiss => 'Dismiss';

  @override
  String get agentHomePromptTitle => 'Make the agent your main screen?';

  @override
  String get agentHomePromptBody =>
      'You can open Finko straight to the agent. Switch back anytime from Settings.';

  @override
  String get agentHomePromptYes => 'Yes, open to agent';

  @override
  String get agentHomePromptNo => 'Not now';

  @override
  String get settingsLaunchScreenAgent => 'Open app to agent';

  @override
  String get settingsLaunchScreenDashboard => 'Open app to dashboard';

  @override
  String get settingsAgentDefaults => 'Agent defaults';

  @override
  String get agentStatusReceiving => 'Got it — one sec…';

  @override
  String get agentStatusReadingReceipt => 'Receipt detective mode…';

  @override
  String get agentStatusExtractingAmount => 'Hunting for numbers…';

  @override
  String get agentStatusTranscribing => 'Ears on — decoding your voice note…';

  @override
  String get agentStatusUnderstanding => 'Turning words into money moves…';

  @override
  String get agentStatusThinking => 'Doing the math in my head…';

  @override
  String get agentStatusAlmostThere => 'Almost there…';

  @override
  String get agentStatusLoadingCategories => 'Rounding up your categories…';

  @override
  String get agentStatusLoadingAccounts => 'Checking which account…';

  @override
  String get agentStatusSaving => 'Locking it in…';

  @override
  String get agentErrorGeneric => 'Hmm, I tripped on that one.';

  @override
  String get agentErrorMedia =>
      'Couldn\'t make sense of that file — try another?';

  @override
  String get agentErrorTimeout => 'That took too long — want to send it again?';

  @override
  String get agentConfirmTitle => 'Ready to save?';

  @override
  String get agentConfirmSave => 'Save it';

  @override
  String get agentConfirmCancel => 'Not now';

  @override
  String get agentCancel => 'Cancel';

  @override
  String get agentSelectOption => 'Select an option…';

  @override
  String get agentDirectionIncome => 'Income';

  @override
  String get agentDirectionExpense => 'Expense';

  @override
  String get agentFieldCategory => 'Category';

  @override
  String get agentFieldAccount => 'Account';

  @override
  String get agentFieldNote => 'Note';

  @override
  String get agentFieldAmount => 'Amount';

  @override
  String get agentEditAmountTitle => 'Edit amount';

  @override
  String get agentEditMemoTitle => 'Edit note';

  @override
  String get agentEditCategoryTitle => 'Choose category';

  @override
  String get agentEditAccountTitle => 'Choose account';

  @override
  String get agentEditDirectionTitle => 'Transaction type';

  @override
  String get agentEditDone => 'Done';

  @override
  String get agentEditAmountInvalid =>
      'Enter a valid amount greater than zero.';

  @override
  String get agentPickCategory => 'Which category fits best?';

  @override
  String get agentPickAccount => 'Which account should I use?';

  @override
  String get agentMissingCategoryHint => 'Choose a category below to continue.';

  @override
  String get agentMissingAccountHint => 'Choose an account below to continue.';

  @override
  String get agentPickTransferAccount => 'Pick an account for this transfer';

  @override
  String get agentTransferTitle => 'Transfer preview';

  @override
  String get agentTransferFrom => 'From';

  @override
  String get agentTransferTo => 'To';

  @override
  String get agentRecurringTitle => 'How often should this repeat?';

  @override
  String get agentCardBuilding => 'Building your transaction…';

  @override
  String get agentFieldSuggested => 'Suggested';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialBack => 'Back';

  @override
  String get tutorialSkip => 'Skip tour';

  @override
  String get tutorialDone => 'Done';

  @override
  String get showTutorial => 'Show tutorial';

  @override
  String get tutorialWelcomeTitle => 'Welcome to Finko';

  @override
  String get tutorialWelcomeBody =>
      'A quick tour of where everything lives. You can skip anytime.';

  @override
  String get tutorialNavBottomTitle => 'Main navigation';

  @override
  String get tutorialNavBottomBody =>
      'Switch between Dashboard, Recurring, Spending, and Transactions. The + in the center adds a transaction.';

  @override
  String get tutorialMenuCogTitle => 'Menu and settings';

  @override
  String get tutorialMenuCogBody =>
      'Open the menu for Categories, Accounts, and Settings. Your month snapshot lives here too.';

  @override
  String get tutorialDrawerSnapshotTitle => 'Your month at a glance';

  @override
  String get tutorialDrawerSnapshotBody =>
      'Net worth, income, expenses, and savings rate for the current month.';

  @override
  String get tutorialDrawerNavTitle => 'Shortcuts';

  @override
  String get tutorialDrawerNavBody =>
      'Jump to Categories, Accounts, or Settings without losing your place.';

  @override
  String get tutorialDashboardCarouselTitle => 'Net worth and spending';

  @override
  String get tutorialDashboardCarouselBody =>
      'Swipe between Net worth (30-day trend) and Monthly expense. Tap a card for Accounts or Spending.';

  @override
  String get tutorialDashboardAccountsTitle => 'Accounts on the dashboard';

  @override
  String get tutorialDashboardAccountsBody =>
      'Expand checking, cards, and savings. Net cash is your spendable balance — tap i to learn how it\'s calculated.';

  @override
  String get tutorialDashboardUpcomingTitle => 'Coming up';

  @override
  String get tutorialDashboardUpcomingBody =>
      'See the next few bills and income. Tap a card to edit; See all opens Recurring.';

  @override
  String get tutorialDashboardBudgetTitle => 'This month\'s budget';

  @override
  String get tutorialDashboardBudgetBody =>
      'Left for spending and top categories. Tap to open the full Budgets screen.';

  @override
  String get tutorialRecurringCalendarTitle => 'Recurring calendar';

  @override
  String get tutorialRecurringCalendarBody =>
      'Green dots = income, blue = expenses. Plan the next two weeks at a glance.';

  @override
  String get tutorialRecurringDueSoonTitle => 'Due soon';

  @override
  String get tutorialRecurringDueSoonBody =>
      'Items due in the next 7 days. Tap to view or edit.';

  @override
  String get tutorialRecurringComingLaterTitle => 'Coming later';

  @override
  String get tutorialRecurringComingLaterBody =>
      'Scheduled items 8–15 days out.';

  @override
  String get tutorialNewTransactionTitle => 'Log a transaction';

  @override
  String get tutorialNewTransactionBody =>
      'Tap + to record income, expenses, or transfers. Same editor opens when you tap any transaction row.';

  @override
  String get tutorialSpendingPillTitle => 'Choose a period';

  @override
  String get tutorialSpendingPillBody =>
      'Pick week, month, quarter, or year — then select which period in the strip.';

  @override
  String get tutorialSpendingStripTitle => 'Period overview';

  @override
  String get tutorialSpendingStripBody =>
      'Each card shows income vs expense for that period. Only periods with activity appear.';

  @override
  String get tutorialSpendingDonutTitle => 'Where your money went';

  @override
  String get tutorialSpendingDonutBody =>
      'Category breakdown for the selected period, plus income, fixed, and variable totals above.';

  @override
  String get tutorialTransactionsSearchTitle => 'Search and filter';

  @override
  String get tutorialTransactionsSearchBody =>
      'Find transactions by memo or filter by type (standard, transfer, adjustment).';

  @override
  String get tutorialTransactionsListTitle => 'Full ledger';

  @override
  String get tutorialTransactionsListBody =>
      'Newest first. Tap any row to edit. Pull down to refresh.';

  @override
  String get tutorialCategoriesTitle => 'Categories';

  @override
  String get tutorialCategoriesBody =>
      'Income and expense categories with this month\'s totals. Tap a row to edit; Add category at the bottom.';

  @override
  String get tutorialAccountsTitle => 'Accounts';

  @override
  String get tutorialAccountsBody =>
      'All accounts grouped by type. Tap for details; Add account to create another.';

  @override
  String get tutorialBudgetsTitle => 'Budgets';

  @override
  String get tutorialBudgetsBody =>
      'Move month by month. Track left to spend, fixed expenses, earnings, savings, and per-category budgets.';

  @override
  String get tutorialSettingsTitle => 'Settings';

  @override
  String get tutorialSettingsBody =>
      'Theme, messaging integrations, launch preferences, and account actions. Replay the tour from Show tutorial here anytime — or from the drawer during your first two weeks.';

  @override
  String get tutorialAgentTitle => 'Finko Agent';

  @override
  String get tutorialAgentBody =>
      'Chat to log transactions with text, photos, or voice — your fastest capture path.';

  @override
  String get tutorialDoneTitle => 'You\'re all set';

  @override
  String get tutorialDoneBody =>
      'Start on the Dashboard or open the Agent anytime.';

  @override
  String get tutorialPreviewTxnGroceries => 'Groceries';

  @override
  String get tutorialPreviewTxnPaycheck => 'Paycheck';

  @override
  String get tutorialPreviewTxnUtilities => 'Utilities';

  @override
  String get tutorialPreviewUpcomingSalary => 'Salary';

  @override
  String get tutorialPreviewUpcomingRent => 'Rent';

  @override
  String get tutorialPreviewCategoryExpense => 'Dining out';

  @override
  String get tutorialPreviewCategoryIncome => 'Side income';

  @override
  String get tutorialPreviewAccountChecking => 'Checking';

  @override
  String get tutorialPreviewBudgetSample => 'Sample budget view';
}
