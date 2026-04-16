import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Finko'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get dashboardTitle;

  /// No description provided for @dashboardHeadline.
  ///
  /// In es, this message translates to:
  /// **'Resumen de tu dinero'**
  String get dashboardHeadline;

  /// No description provided for @openSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get openSettings;

  /// No description provided for @openOnboarding.
  ///
  /// In es, this message translates to:
  /// **'Incorporación'**
  String get openOnboarding;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la app'**
  String get settingsLanguageLabel;

  /// No description provided for @localeSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get localeSpanish;

  /// No description provided for @localeEnglish.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get localeEnglish;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Perfil y preferencias'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingDisplayNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre para mostrar'**
  String get onboardingDisplayNameLabel;

  /// No description provided for @onboardingTimezoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria'**
  String get onboardingTimezoneLabel;

  /// No description provided for @onboardingThemeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get onboardingThemeLabel;

  /// No description provided for @onboardingLocaleLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get onboardingLocaleLabel;

  /// No description provided for @onboardingNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @environmentBanner.
  ///
  /// In es, this message translates to:
  /// **'[{env}]'**
  String environmentBanner(String env);

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPasswordLabel;

  /// No description provided for @loginSignIn.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get loginSignIn;

  /// No description provided for @loginCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get loginCreateAccount;

  /// No description provided for @loginToggleSignUp.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Crear cuenta'**
  String get loginToggleSignUp;

  /// No description provided for @loginToggleSignIn.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Entrar'**
  String get loginToggleSignIn;

  /// No description provided for @loginGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginGoogle;

  /// No description provided for @loginApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get loginApple;

  /// No description provided for @loginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get loginForgotPassword;

  /// No description provided for @loginForgotPasswordMissingEmail.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu correo arriba para restablecer la contraseña'**
  String get loginForgotPasswordMissingEmail;

  /// No description provided for @loginForgotPasswordSent.
  ///
  /// In es, this message translates to:
  /// **'Se envió el correo para restablecer la contraseña. Revisa tu bandeja.'**
  String get loginForgotPasswordSent;

  /// No description provided for @loginValidationRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get loginValidationRequired;

  /// No description provided for @loginValidationEmail.
  ///
  /// In es, this message translates to:
  /// **'Introduce un correo válido'**
  String get loginValidationEmail;

  /// No description provided for @loginValidationPasswordLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get loginValidationPasswordLength;

  /// No description provided for @loginErrorInvalidCredential.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get loginErrorInvalidCredential;

  /// No description provided for @loginErrorEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Este correo ya está registrado'**
  String get loginErrorEmailInUse;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar el inicio de sesión'**
  String get loginErrorGeneric;

  /// No description provided for @settingsSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOut;

  /// No description provided for @dashboardSignedInAs.
  ///
  /// In es, this message translates to:
  /// **'Sesión: {email}'**
  String dashboardSignedInAs(String email);

  /// No description provided for @navDashboard.
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get navDashboard;

  /// No description provided for @navRecurring.
  ///
  /// In es, this message translates to:
  /// **'Recurrente'**
  String get navRecurring;

  /// No description provided for @navSpending.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get navSpending;

  /// No description provided for @navTransactions.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get navTransactions;

  /// No description provided for @navMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get navMore;

  /// No description provided for @drawerCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get drawerCategories;

  /// No description provided for @drawerAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get drawerAccounts;

  /// No description provided for @drawerUserPlaceholderName.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get drawerUserPlaceholderName;

  /// No description provided for @drawerUserPlaceholderEmail.
  ///
  /// In es, this message translates to:
  /// **' '**
  String get drawerUserPlaceholderEmail;

  /// No description provided for @drawerUserPlaceholderInitial.
  ///
  /// In es, this message translates to:
  /// **'F'**
  String get drawerUserPlaceholderInitial;

  /// No description provided for @recurringTitle.
  ///
  /// In es, this message translates to:
  /// **'Recurrente'**
  String get recurringTitle;

  /// No description provided for @spendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get spendingTitle;

  /// No description provided for @transactionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get transactionsTitle;

  /// No description provided for @budgetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get budgetsTitle;

  /// No description provided for @categoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categoriesTitle;

  /// No description provided for @accountsTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get accountsTitle;

  /// No description provided for @metricNetWorth.
  ///
  /// In es, this message translates to:
  /// **'Patrimonio neto'**
  String get metricNetWorth;

  /// No description provided for @metricMonthlyExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto del mes'**
  String get metricMonthlyExpense;

  /// No description provided for @metricDeltaStubUp.
  ///
  /// In es, this message translates to:
  /// **'+2,1 %'**
  String get metricDeltaStubUp;

  /// No description provided for @metricDeltaStubDown.
  ///
  /// In es, this message translates to:
  /// **'-1,0 %'**
  String get metricDeltaStubDown;

  /// No description provided for @accountTypeChecking.
  ///
  /// In es, this message translates to:
  /// **'Cuenta corriente'**
  String get accountTypeChecking;

  /// No description provided for @accountTypeCreditCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas de crédito'**
  String get accountTypeCreditCard;

  /// No description provided for @accountTypeSavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorros'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeInvestment.
  ///
  /// In es, this message translates to:
  /// **'Inversiones'**
  String get accountTypeInvestment;

  /// No description provided for @netCashLabel.
  ///
  /// In es, this message translates to:
  /// **'Efectivo neto'**
  String get netCashLabel;

  /// No description provided for @loansMortgageSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Préstamos e hipoteca'**
  String get loansMortgageSectionTitle;

  /// No description provided for @dashboardAccountsHeading.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get dashboardAccountsHeading;

  /// No description provided for @dashboardUpcomingHeading.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get dashboardUpcomingHeading;

  /// No description provided for @dashboardRecentHeading.
  ///
  /// In es, this message translates to:
  /// **'Movimientos recientes'**
  String get dashboardRecentHeading;

  /// No description provided for @seeMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get seeMore;

  /// No description provided for @leftForSpending.
  ///
  /// In es, this message translates to:
  /// **'Disponible para gastar'**
  String get leftForSpending;

  /// No description provided for @thisMonthsBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto del mes'**
  String get thisMonthsBudget;

  /// No description provided for @upcomingToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get upcomingToday;

  /// No description provided for @upcomingTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get upcomingTomorrow;

  /// No description provided for @upcomingInDays.
  ///
  /// In es, this message translates to:
  /// **'{count} días'**
  String upcomingInDays(int count);

  /// No description provided for @emptyNoAccounts.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay cuentas.'**
  String get emptyNoAccounts;

  /// No description provided for @emptyNoTransactions.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay movimientos.'**
  String get emptyNoTransactions;

  /// No description provided for @emptyNoUpcoming.
  ///
  /// In es, this message translates to:
  /// **'No hay próximos movimientos.'**
  String get emptyNoUpcoming;

  /// No description provided for @emptyNoMonthlyTotals.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay totales del mes — añade un movimiento.'**
  String get emptyNoMonthlyTotals;

  /// No description provided for @spendingPeriodWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get spendingPeriodWeek;

  /// No description provided for @spendingPeriodMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get spendingPeriodMonth;

  /// No description provided for @spendingPeriodQuarter.
  ///
  /// In es, this message translates to:
  /// **'Trimestre'**
  String get spendingPeriodQuarter;

  /// No description provided for @spendingPeriodYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get spendingPeriodYear;

  /// No description provided for @spendingIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get spendingIncome;

  /// No description provided for @spendingExpense.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get spendingExpense;

  /// No description provided for @spendingTotalSpend.
  ///
  /// In es, this message translates to:
  /// **'Gasto total'**
  String get spendingTotalSpend;

  /// No description provided for @spendingInPeriod.
  ///
  /// In es, this message translates to:
  /// **'En {period}'**
  String spendingInPeriod(String period);

  /// No description provided for @spendingTopTransactions.
  ///
  /// In es, this message translates to:
  /// **'Principales movimientos'**
  String get spendingTopTransactions;

  /// No description provided for @transactionsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar movimientos'**
  String get transactionsSearchHint;

  /// No description provided for @budgetsThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get budgetsThisMonth;

  /// No description provided for @budgetsPaceSlashDay.
  ///
  /// In es, this message translates to:
  /// **'/día'**
  String get budgetsPaceSlashDay;

  /// No description provided for @budgetsDaysRemainingInMonth.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{0 días restantes} one{1 día restante} other{{count} días restantes}}'**
  String budgetsDaysRemainingInMonth(int count);

  /// No description provided for @budgetsSpendingPace.
  ///
  /// In es, this message translates to:
  /// **'{paceWithDayUnit} · {daysPhrase}'**
  String budgetsSpendingPace(String paceWithDayUnit, String daysPhrase);

  /// No description provided for @budgetsSpendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get budgetsSpendingTitle;

  /// No description provided for @budgetsLeftToSpend.
  ///
  /// In es, this message translates to:
  /// **'disponible para gastar'**
  String get budgetsLeftToSpend;

  /// No description provided for @budgetsSpent.
  ///
  /// In es, this message translates to:
  /// **'Gastado'**
  String get budgetsSpent;

  /// No description provided for @budgetsBudgeted.
  ///
  /// In es, this message translates to:
  /// **'Presupuestado'**
  String get budgetsBudgeted;

  /// No description provided for @budgetsBillsUtilities.
  ///
  /// In es, this message translates to:
  /// **'Facturas y servicios'**
  String get budgetsBillsUtilities;

  /// No description provided for @budgetsEarnings.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get budgetsEarnings;

  /// No description provided for @budgetsProjectedSavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorro previsto'**
  String get budgetsProjectedSavings;

  /// No description provided for @budgetsOfTarget.
  ///
  /// In es, this message translates to:
  /// **'De {amount} objetivo'**
  String budgetsOfTarget(String amount);

  /// No description provided for @budgetsCategoryBudgets.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos por categoría'**
  String get budgetsCategoryBudgets;

  /// No description provided for @recurringThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get recurringThisWeek;

  /// No description provided for @recurringNextWeek.
  ///
  /// In es, this message translates to:
  /// **'Próxima semana'**
  String get recurringNextWeek;

  /// No description provided for @recurringComingUp.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get recurringComingUp;

  /// No description provided for @recurringDueSoon.
  ///
  /// In es, this message translates to:
  /// **'Pronto'**
  String get recurringDueSoon;

  /// No description provided for @recurringComingLater.
  ///
  /// In es, this message translates to:
  /// **'Más adelante'**
  String get recurringComingLater;

  /// No description provided for @categoriesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay categorías en los datos del mes.'**
  String get categoriesEmpty;

  /// No description provided for @accountsListSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Toca una cuenta cuando existan detalles.'**
  String get accountsListSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
