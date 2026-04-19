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

  /// No description provided for @onboardingBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get onboardingBack;

  /// No description provided for @onboardingCommit.
  ///
  /// In es, this message translates to:
  /// **'Finalizar incorporación'**
  String get onboardingCommit;

  /// No description provided for @onboardingCompleted.
  ///
  /// In es, this message translates to:
  /// **'Incorporación completada.'**
  String get onboardingCompleted;

  /// No description provided for @onboardingStepProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil y preferencias'**
  String get onboardingStepProfileTitle;

  /// No description provided for @onboardingStepAccountsTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get onboardingStepAccountsTitle;

  /// No description provided for @onboardingStepCategoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get onboardingStepCategoriesTitle;

  /// No description provided for @onboardingStepRecurringTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresos recurrentes'**
  String get onboardingStepRecurringTitle;

  /// No description provided for @onboardingStepBudgetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get onboardingStepBudgetsTitle;

  /// No description provided for @onboardingStepProjectedTitle.
  ///
  /// In es, this message translates to:
  /// **'Ahorro proyectado'**
  String get onboardingStepProjectedTitle;

  /// No description provided for @onboardingStepMessagingTitle.
  ///
  /// In es, this message translates to:
  /// **'Mensajería'**
  String get onboardingStepMessagingTitle;

  /// No description provided for @onboardingStepReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisar y finalizar'**
  String get onboardingStepReviewTitle;

  /// No description provided for @onboardingReviewIntro.
  ///
  /// In es, this message translates to:
  /// **'Revisa lo siguiente. Toca finalizar para guardar tu configuración en Finko.'**
  String get onboardingReviewIntro;

  /// No description provided for @onboardingReviewPreferences.
  ///
  /// In es, this message translates to:
  /// **'Tus elecciones'**
  String get onboardingReviewPreferences;

  /// No description provided for @onboardingReviewSectionAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get onboardingReviewSectionAccounts;

  /// No description provided for @onboardingReviewSectionCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get onboardingReviewSectionCategories;

  /// No description provided for @onboardingReviewCategoriesCounts.
  ///
  /// In es, this message translates to:
  /// **'Categorías de ingreso: {incomeCount} · Categorías de gasto: {expenseCount}'**
  String onboardingReviewCategoriesCounts(int incomeCount, int expenseCount);

  /// No description provided for @onboardingReviewSectionRecurring.
  ///
  /// In es, this message translates to:
  /// **'Ingresos recurrentes'**
  String get onboardingReviewSectionRecurring;

  /// No description provided for @onboardingReviewSectionBudgets.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos mensuales'**
  String get onboardingReviewSectionBudgets;

  /// No description provided for @onboardingReviewSectionProjected.
  ///
  /// In es, this message translates to:
  /// **'Ahorro mensual proyectado'**
  String get onboardingReviewSectionProjected;

  /// No description provided for @onboardingReviewSectionMessaging.
  ///
  /// In es, this message translates to:
  /// **'Mensajería'**
  String get onboardingReviewSectionMessaging;

  /// No description provided for @onboardingReviewMessagingNone.
  ///
  /// In es, this message translates to:
  /// **'Sin canales verificados (puedes conectar después).'**
  String get onboardingReviewMessagingNone;

  /// No description provided for @onboardingReviewMessagingWhatsAppOk.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp verificado'**
  String get onboardingReviewMessagingWhatsAppOk;

  /// No description provided for @onboardingReviewMessagingTelegramOk.
  ///
  /// In es, this message translates to:
  /// **'Telegram verificado'**
  String get onboardingReviewMessagingTelegramOk;

  /// No description provided for @onboardingReviewRecurringOff.
  ///
  /// In es, this message translates to:
  /// **'No recurrente'**
  String get onboardingReviewRecurringOff;

  /// No description provided for @onboardingReviewBiweeklyDays.
  ///
  /// In es, this message translates to:
  /// **'Pagos: días {day1} y {day2}'**
  String onboardingReviewBiweeklyDays(int day1, int day2);

  /// No description provided for @onboardingFirstPaydayLabel.
  ///
  /// In es, this message translates to:
  /// **'Primer pago (día del mes)'**
  String get onboardingFirstPaydayLabel;

  /// No description provided for @onboardingSecondPaydayLabel.
  ///
  /// In es, this message translates to:
  /// **'Segundo pago (día del mes)'**
  String get onboardingSecondPaydayLabel;

  /// No description provided for @onboardingStepCommitTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardando configuración'**
  String get onboardingStepCommitTitle;

  /// No description provided for @onboardingStepDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get onboardingStepDoneTitle;

  /// No description provided for @onboardingAccountName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la cuenta'**
  String get onboardingAccountName;

  /// No description provided for @onboardingAddAccount.
  ///
  /// In es, this message translates to:
  /// **'Agregar cuenta'**
  String get onboardingAddAccount;

  /// No description provided for @onboardingCategoryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la categoría'**
  String get onboardingCategoryName;

  /// No description provided for @onboardingAddCategory.
  ///
  /// In es, this message translates to:
  /// **'Agregar categoría'**
  String get onboardingAddCategory;

  /// No description provided for @onboardingRecurringQuestion.
  ///
  /// In es, this message translates to:
  /// **'Recurrente'**
  String get onboardingRecurringQuestion;

  /// No description provided for @onboardingNoIncomeCategories.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay categorías de ingreso.'**
  String get onboardingNoIncomeCategories;

  /// No description provided for @onboardingExpectedIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso esperado'**
  String get onboardingExpectedIncome;

  /// No description provided for @onboardingFixedExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos fijos'**
  String get onboardingFixedExpenses;

  /// No description provided for @onboardingVariableExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos variables'**
  String get onboardingVariableExpenses;

  /// No description provided for @onboardingProjectedSavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorro proyectado'**
  String get onboardingProjectedSavings;

  /// No description provided for @onboardingMessagingIdentity.
  ///
  /// In es, this message translates to:
  /// **'Teléfono o usuario de Telegram'**
  String get onboardingMessagingIdentity;

  /// No description provided for @onboardingRequestOtpWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'Solicitar OTP de WhatsApp'**
  String get onboardingRequestOtpWhatsApp;

  /// No description provided for @onboardingRequestOtpTelegram.
  ///
  /// In es, this message translates to:
  /// **'Solicitar OTP de Telegram'**
  String get onboardingRequestOtpTelegram;

  /// No description provided for @onboardingOtpCode.
  ///
  /// In es, this message translates to:
  /// **'Código OTP'**
  String get onboardingOtpCode;

  /// No description provided for @onboardingVerifyWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'Verificar WhatsApp'**
  String get onboardingVerifyWhatsApp;

  /// No description provided for @onboardingVerifyTelegram.
  ///
  /// In es, this message translates to:
  /// **'Verificar Telegram'**
  String get onboardingVerifyTelegram;

  /// No description provided for @onboardingRemindMeLater.
  ///
  /// In es, this message translates to:
  /// **'Recordármelo después'**
  String get onboardingRemindMeLater;

  /// No description provided for @onboardingContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboardingContinue;

  /// No description provided for @onboardingLocaleSpanishMx.
  ///
  /// In es, this message translates to:
  /// **'Español (México)'**
  String get onboardingLocaleSpanishMx;

  /// No description provided for @onboardingLocaleEnglishUs.
  ///
  /// In es, this message translates to:
  /// **'Inglés (EE. UU.)'**
  String get onboardingLocaleEnglishUs;

  /// No description provided for @onboardingTimezoneMexicoSoutheast.
  ///
  /// In es, this message translates to:
  /// **'México — Zona Sureste (UTC−5)'**
  String get onboardingTimezoneMexicoSoutheast;

  /// No description provided for @onboardingTimezoneMexicoCentral.
  ///
  /// In es, this message translates to:
  /// **'México — Zona Centro (UTC−6)'**
  String get onboardingTimezoneMexicoCentral;

  /// No description provided for @onboardingTimezoneMexicoPacific.
  ///
  /// In es, this message translates to:
  /// **'México — Zona Pacífico (UTC−7)'**
  String get onboardingTimezoneMexicoPacific;

  /// No description provided for @onboardingTimezoneMexicoNorthwest.
  ///
  /// In es, this message translates to:
  /// **'México — Zona Noroeste (UTC−8)'**
  String get onboardingTimezoneMexicoNorthwest;

  /// No description provided for @onboardingTimezoneUsPacific.
  ///
  /// In es, this message translates to:
  /// **'Estados Unidos — Pacífico'**
  String get onboardingTimezoneUsPacific;

  /// No description provided for @onboardingTimezoneUsMountain.
  ///
  /// In es, this message translates to:
  /// **'Estados Unidos — Montaña'**
  String get onboardingTimezoneUsMountain;

  /// No description provided for @onboardingTimezoneUsEastern.
  ///
  /// In es, this message translates to:
  /// **'Estados Unidos — Este'**
  String get onboardingTimezoneUsEastern;

  /// No description provided for @onboardingCategoryFixedExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos fijos'**
  String get onboardingCategoryFixedExpenses;

  /// No description provided for @onboardingFixedExpensesInfoTooltip.
  ///
  /// In es, this message translates to:
  /// **'Acerca de gastos fijos'**
  String get onboardingFixedExpensesInfoTooltip;

  /// No description provided for @onboardingFixedExpensesInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Por qué gastos fijos está bloqueado'**
  String get onboardingFixedExpensesInfoTitle;

  /// No description provided for @onboardingFixedExpensesInfoBody.
  ///
  /// In es, this message translates to:
  /// **'Esta categoría está reservada para gastos que se mantienen parecidos cada mes—renta, servicios, mínimos de préstamo, suscripciones y obligaciones similares.\n\nFinko la incluye para que puedas presupuestar esos montos aparte del gasto variable del día a día. Durante la incorporación no se puede renombrar ni eliminar; solo defines cuánto presupuestas en el siguiente paso.'**
  String get onboardingFixedExpensesInfoBody;

  /// No description provided for @onboardingGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get onboardingGotIt;

  /// No description provided for @onboardingCategoryKindIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get onboardingCategoryKindIncome;

  /// No description provided for @onboardingCategoryKindExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get onboardingCategoryKindExpense;

  /// No description provided for @onboardingPickIcon.
  ///
  /// In es, this message translates to:
  /// **'Ícono'**
  String get onboardingPickIcon;

  /// No description provided for @onboardingSectionColor.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get onboardingSectionColor;

  /// No description provided for @onboardingCadenceWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get onboardingCadenceWeekly;

  /// No description provided for @onboardingWeekdayLabel.
  ///
  /// In es, this message translates to:
  /// **'Día de la semana'**
  String get onboardingWeekdayLabel;

  /// No description provided for @onboardingCategoriesSectionIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get onboardingCategoriesSectionIncome;

  /// No description provided for @onboardingCategoriesSectionExpense.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get onboardingCategoriesSectionExpense;

  /// No description provided for @onboardingSaveCategory.
  ///
  /// In es, this message translates to:
  /// **'Guardar categoría'**
  String get onboardingSaveCategory;

  /// No description provided for @onboardingEditCategory.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get onboardingEditCategory;

  /// No description provided for @onboardingProjectedChartTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo suma tu presupuesto mensual'**
  String get onboardingProjectedChartTitle;

  /// No description provided for @onboardingSuggestedSalary.
  ///
  /// In es, this message translates to:
  /// **'Salario'**
  String get onboardingSuggestedSalary;

  /// No description provided for @onboardingSuggestedFood.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get onboardingSuggestedFood;

  /// No description provided for @onboardingSuggestedTransport.
  ///
  /// In es, this message translates to:
  /// **'Transporte'**
  String get onboardingSuggestedTransport;

  /// No description provided for @onboardingAddSuggested.
  ///
  /// In es, this message translates to:
  /// **'Añadir sugerida'**
  String get onboardingAddSuggested;

  /// No description provided for @onboardingAccountTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cuenta'**
  String get onboardingAccountTypeLabel;

  /// No description provided for @onboardingCurrencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get onboardingCurrencyLabel;

  /// No description provided for @onboardingStartingBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo inicial'**
  String get onboardingStartingBalanceLabel;

  /// No description provided for @onboardingSaveAccount.
  ///
  /// In es, this message translates to:
  /// **'Guardar cuenta'**
  String get onboardingSaveAccount;

  /// No description provided for @onboardingEditAccount.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get onboardingEditAccount;

  /// No description provided for @onboardingRecurringAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto (moneda principal)'**
  String get onboardingRecurringAmountLabel;

  /// No description provided for @onboardingDepositAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de depósito'**
  String get onboardingDepositAccountLabel;

  /// No description provided for @onboardingCadenceLabel.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get onboardingCadenceLabel;

  /// No description provided for @onboardingCadenceMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get onboardingCadenceMonthly;

  /// No description provided for @onboardingCadenceTwiceMonthly.
  ///
  /// In es, this message translates to:
  /// **'Dos veces al mes'**
  String get onboardingCadenceTwiceMonthly;

  /// No description provided for @onboardingCadenceBiweekly.
  ///
  /// In es, this message translates to:
  /// **'Quincenal (cada 14 días)'**
  String get onboardingCadenceBiweekly;

  /// No description provided for @onboardingDayOfMonthLabel.
  ///
  /// In es, this message translates to:
  /// **'Día del mes (1–31)'**
  String get onboardingDayOfMonthLabel;

  /// No description provided for @onboardingSecondDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Segundo día (1–31)'**
  String get onboardingSecondDayLabel;

  /// No description provided for @onboardingHintInvalidMonthDay.
  ///
  /// In es, this message translates to:
  /// **'Si el día no existe en un mes, se usa el último día de ese mes.'**
  String get onboardingHintInvalidMonthDay;

  /// No description provided for @onboardingValidationProfileNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para mostrar.'**
  String get onboardingValidationProfileNameRequired;

  /// No description provided for @onboardingValidationProfileNameTooLong.
  ///
  /// In es, this message translates to:
  /// **'El nombre para mostrar es demasiado largo.'**
  String get onboardingValidationProfileNameTooLong;

  /// No description provided for @onboardingValidationAccountsMinOne.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos una cuenta.'**
  String get onboardingValidationAccountsMinOne;

  /// No description provided for @onboardingValidationAccountNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Cada cuenta necesita un nombre.'**
  String get onboardingValidationAccountNameRequired;

  /// No description provided for @onboardingValidationCategoriesFixed.
  ///
  /// In es, this message translates to:
  /// **'Falta la categoría de gastos fijos.'**
  String get onboardingValidationCategoriesFixed;

  /// No description provided for @onboardingValidationRecurringAmount.
  ///
  /// In es, this message translates to:
  /// **'Indica un monto recurrente mayor que cero.'**
  String get onboardingValidationRecurringAmount;

  /// No description provided for @onboardingValidationRecurringAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta de depósito para el ingreso recurrente.'**
  String get onboardingValidationRecurringAccount;

  /// No description provided for @onboardingValidationRecurringDaysTwice.
  ///
  /// In es, this message translates to:
  /// **'Elige ambos días de pago (días del mes) para ingreso quincenal.'**
  String get onboardingValidationRecurringDaysTwice;

  /// No description provided for @onboardingValidationRecurringDayMonthly.
  ///
  /// In es, this message translates to:
  /// **'Elige un día del mes.'**
  String get onboardingValidationRecurringDayMonthly;

  /// No description provided for @onboardingValidationRecurringDayRange.
  ///
  /// In es, this message translates to:
  /// **'Usa días entre 1 y 31.'**
  String get onboardingValidationRecurringDayRange;

  /// No description provided for @onboardingValidationRecurringWeekday.
  ///
  /// In es, this message translates to:
  /// **'Elige un día de la semana.'**
  String get onboardingValidationRecurringWeekday;

  /// No description provided for @onboardingValidationBudgetMissing.
  ///
  /// In es, this message translates to:
  /// **'Indica un presupuesto para cada categoría.'**
  String get onboardingValidationBudgetMissing;

  /// No description provided for @onboardingMessagingWhatsAppHint.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp: teléfono en E.164 (p. ej. +525512345678)'**
  String get onboardingMessagingWhatsAppHint;

  /// No description provided for @onboardingMessagingTelegramHint.
  ///
  /// In es, this message translates to:
  /// **'Telegram: @usuario'**
  String get onboardingMessagingTelegramHint;

  /// No description provided for @accountTypeLoan.
  ///
  /// In es, this message translates to:
  /// **'Préstamo'**
  String get accountTypeLoan;

  /// No description provided for @accountTypeMortgage.
  ///
  /// In es, this message translates to:
  /// **'Hipoteca'**
  String get accountTypeMortgage;

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

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tema de color'**
  String get settingsThemeLabel;

  /// No description provided for @settingsMembershipSection.
  ///
  /// In es, this message translates to:
  /// **'Membresía'**
  String get settingsMembershipSection;

  /// No description provided for @settingsManagePlan.
  ///
  /// In es, this message translates to:
  /// **'Administrar tu plan'**
  String get settingsManagePlan;

  /// No description provided for @settingsManagePlanSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Abre la facturación de Stripe (próximamente).'**
  String get settingsManagePlanSubtitle;

  /// No description provided for @settingsComingSoonLabel.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get settingsComingSoonLabel;

  /// No description provided for @settingsMessagingSection.
  ///
  /// In es, this message translates to:
  /// **'Mensajería'**
  String get settingsMessagingSection;

  /// No description provided for @settingsMessagingWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get settingsMessagingWhatsApp;

  /// No description provided for @settingsMessagingTelegram.
  ///
  /// In es, this message translates to:
  /// **'Telegram'**
  String get settingsMessagingTelegram;

  /// No description provided for @settingsMessagingStatusConnected.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get settingsMessagingStatusConnected;

  /// No description provided for @settingsMessagingStatusNotConnected.
  ///
  /// In es, this message translates to:
  /// **'Sin conectar'**
  String get settingsMessagingStatusNotConnected;

  /// No description provided for @settingsMessagingConnectedWhatsAppDetail.
  ///
  /// In es, this message translates to:
  /// **'Número de WhatsApp: {phone}'**
  String settingsMessagingConnectedWhatsAppDetail(String phone);

  /// No description provided for @settingsMessagingConnectedTelegramDetail.
  ///
  /// In es, this message translates to:
  /// **'Telegram: {username}'**
  String settingsMessagingConnectedTelegramDetail(String username);

  /// No description provided for @settingsMessagingVerifiedOn.
  ///
  /// In es, this message translates to:
  /// **'Verificado el {date}'**
  String settingsMessagingVerifiedOn(String date);

  /// No description provided for @settingsMessagingDisconnect.
  ///
  /// In es, this message translates to:
  /// **'Desconectar'**
  String get settingsMessagingDisconnect;

  /// No description provided for @settingsMessagingDisconnectConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Desconectar este canal?'**
  String get settingsMessagingDisconnectConfirmTitle;

  /// No description provided for @settingsMessagingDisconnectConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes volver a conectarlo cuando quieras desde Ajustes.'**
  String get settingsMessagingDisconnectConfirmBody;

  /// No description provided for @settingsMessagingDisconnectConfirmCta.
  ///
  /// In es, this message translates to:
  /// **'Desconectar'**
  String get settingsMessagingDisconnectConfirmCta;

  /// No description provided for @settingsMessagingDisconnectCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get settingsMessagingDisconnectCancel;

  /// No description provided for @settingsErrorSave.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar. Intenta de nuevo.'**
  String get settingsErrorSave;

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

  /// No description provided for @navNewTransaction.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get navNewTransaction;

  /// No description provided for @navSpending.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get navSpending;

  /// No description provided for @navTransactions.
  ///
  /// In es, this message translates to:
  /// **'Transacciones'**
  String get navTransactions;

  /// No description provided for @openShellMenu.
  ///
  /// In es, this message translates to:
  /// **'Abrir menú'**
  String get openShellMenu;

  /// No description provided for @newTransactionSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva transacción'**
  String get newTransactionSheetTitle;

  /// No description provided for @newTransactionSheetBody.
  ///
  /// In es, this message translates to:
  /// **'Añade una transacción'**
  String get newTransactionSheetBody;

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
  /// **'Transacciones'**
  String get transactionsTitle;

  /// No description provided for @budgetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get budgetsTitle;

  /// No description provided for @categoryEditorDeleteCategory.
  ///
  /// In es, this message translates to:
  /// **'Eliminar categoría…'**
  String get categoryEditorDeleteCategory;

  /// No description provided for @accountEditorDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta…'**
  String get accountEditorDeleteAccount;

  /// No description provided for @categoryDeleteCascadeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar “{name}” y todos los datos relacionados?'**
  String categoryDeleteCascadeTitle(String name);

  /// No description provided for @categoryDeleteCascadeBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán {transactions} transacciones, {recurring} reglas recurrentes, {upcoming} próximos y la fila de presupuesto de esta categoría. No se puede deshacer.'**
  String categoryDeleteCascadeBody(
    int transactions,
    int recurring,
    int upcoming,
  );

  /// No description provided for @accountDeleteCascadeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la cuenta “{name}” y todos los datos relacionados?'**
  String accountDeleteCascadeTitle(String name);

  /// No description provided for @accountDeleteCascadeBody.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán {transactions} transacciones (incluidos tramos de transferencia emparejados), {recurring} recurrentes, {upcoming} próximos y luego la cuenta. No se puede deshacer.'**
  String accountDeleteCascadeBody(
    int transactions,
    int recurring,
    int upcoming,
  );

  /// No description provided for @deleteCascadeConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todo'**
  String get deleteCascadeConfirm;

  /// No description provided for @deleteCascadeSuccess.
  ///
  /// In es, this message translates to:
  /// **'Eliminado.'**
  String get deleteCascadeSuccess;

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
  /// **'Debito'**
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

  /// No description provided for @dashboardNetCashInfoTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cómo se calcula el efectivo neto'**
  String get dashboardNetCashInfoTooltip;

  /// No description provided for @dashboardNetCashInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Efectivo neto'**
  String get dashboardNetCashInfoTitle;

  /// No description provided for @dashboardNetCashInfoBody.
  ///
  /// In es, this message translates to:
  /// **'El efectivo neto es un total con signo para las cuentas que cuentan como flujo de efectivo líquido: se suman los saldos de cuentas de activo (por ejemplo, débito) y se restan los importes adeudados en cuentas de pasivo (por ejemplo, tarjetas de crédito).\n\nUna cuenta entra cuando tiene activada la opción “Incluir en efectivo neto”. Si nunca se definió, por defecto se incluyen cuentas de débito y tarjetas de crédito; no se incluyen ahorros, inversiones, préstamos ni hipotecas.\n\nPara cada cuenta incluida, Finko usa el saldo en tu moneda principal cuando existe; si no, el saldo en la moneda de esa cuenta.'**
  String get dashboardNetCashInfoBody;

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
  /// **'Transacciones recientes'**
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
  /// **'Aún no hay transacciones.'**
  String get emptyNoTransactions;

  /// No description provided for @emptyNoUpcoming.
  ///
  /// In es, this message translates to:
  /// **'No hay próximas transacciones.'**
  String get emptyNoUpcoming;

  /// No description provided for @emptyNoMonthlyTotals.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay totales del mes — añade un transacción.'**
  String get emptyNoMonthlyTotals;

  /// No description provided for @summaryMonthTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get summaryMonthTotalLabel;

  /// No description provided for @summaryRecentTransactionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Transacciones recientes'**
  String get summaryRecentTransactionsLabel;

  /// No description provided for @summaryNoTransactionsThisMonth.
  ///
  /// In es, this message translates to:
  /// **'No hay transacciones este mes.'**
  String get summaryNoTransactionsThisMonth;

  /// No description provided for @summaryYearMonthHeading.
  ///
  /// In es, this message translates to:
  /// **'{yearMonth}'**
  String summaryYearMonthHeading(String yearMonth);

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

  /// No description provided for @spendingTotalSpendIn.
  ///
  /// In es, this message translates to:
  /// **'Gasto total'**
  String get spendingTotalSpendIn;

  /// No description provided for @spendingFixedExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos fijos'**
  String get spendingFixedExpenses;

  /// No description provided for @spendingVariableExpenses.
  ///
  /// In es, this message translates to:
  /// **'Gastos variables'**
  String get spendingVariableExpenses;

  /// No description provided for @spendingUncategorized.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get spendingUncategorized;

  /// No description provided for @spendingStripEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay períodos con transacciones en este rango.'**
  String get spendingStripEmpty;

  /// No description provided for @spendingInPeriod.
  ///
  /// In es, this message translates to:
  /// **'En {period}'**
  String spendingInPeriod(String period);

  /// No description provided for @spendingTopTransactions.
  ///
  /// In es, this message translates to:
  /// **'Gastos más grandes'**
  String get spendingTopTransactions;

  /// No description provided for @transactionsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar transacciones'**
  String get transactionsSearchHint;

  /// No description provided for @transactionsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos los tipos'**
  String get transactionsFilterAll;

  /// No description provided for @transactionsFilterStandard.
  ///
  /// In es, this message translates to:
  /// **'Estándar'**
  String get transactionsFilterStandard;

  /// No description provided for @transactionsFilterTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get transactionsFilterTransfer;

  /// No description provided for @transactionsFilterAdjustment.
  ///
  /// In es, this message translates to:
  /// **'Ajuste'**
  String get transactionsFilterAdjustment;

  /// No description provided for @transactionsFilterSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por tipo'**
  String get transactionsFilterSheetTitle;

  /// No description provided for @transactionsSearchSearchingHistory.
  ///
  /// In es, this message translates to:
  /// **'No aparece en lo cargado. Buscando en todo el historial…'**
  String get transactionsSearchSearchingHistory;

  /// No description provided for @transactionsSearchHistoryLimitReached.
  ///
  /// In es, this message translates to:
  /// **'Sin coincidencias en esta parte del historial. Prueba un término más específico.'**
  String get transactionsSearchHistoryLimitReached;

  /// No description provided for @transactionsSearchNoMatches.
  ///
  /// In es, this message translates to:
  /// **'No hay transacciones que coincidan.'**
  String get transactionsSearchNoMatches;

  /// No description provided for @transactionEditorSheetEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar transacción'**
  String get transactionEditorSheetEditTitle;

  /// No description provided for @transactionEditorFieldDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get transactionEditorFieldDate;

  /// No description provided for @transactionEditorFieldAmount.
  ///
  /// In es, this message translates to:
  /// **'Importe'**
  String get transactionEditorFieldAmount;

  /// No description provided for @transactionEditorFieldTransferAmountOut.
  ///
  /// In es, this message translates to:
  /// **'Importe enviado'**
  String get transactionEditorFieldTransferAmountOut;

  /// No description provided for @transactionEditorFieldTransferAmountIn.
  ///
  /// In es, this message translates to:
  /// **'Importe recibido'**
  String get transactionEditorFieldTransferAmountIn;

  /// No description provided for @transactionEditorFieldDirection.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get transactionEditorFieldDirection;

  /// No description provided for @transactionEditorDirectionIn.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get transactionEditorDirectionIn;

  /// No description provided for @transactionEditorDirectionOut.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get transactionEditorDirectionOut;

  /// No description provided for @transactionEditorEntryTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get transactionEditorEntryTransfer;

  /// No description provided for @transactionEditorFieldFromAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta origen'**
  String get transactionEditorFieldFromAccount;

  /// No description provided for @transactionEditorFieldToAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta destino'**
  String get transactionEditorFieldToAccount;

  /// No description provided for @transactionEditorValidationFromAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige la cuenta desde la que sale el dinero.'**
  String get transactionEditorValidationFromAccount;

  /// No description provided for @transactionEditorValidationToAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige la cuenta a la que entra el dinero.'**
  String get transactionEditorValidationToAccount;

  /// No description provided for @transactionEditorValidationTransferSameCurrency.
  ///
  /// In es, this message translates to:
  /// **'Ambas cuentas deben tener la misma moneda para una transferencia.'**
  String get transactionEditorValidationTransferSameCurrency;

  /// No description provided for @transactionEditorValidationTransferDistinctAccounts.
  ///
  /// In es, this message translates to:
  /// **'Elige dos cuentas distintas.'**
  String get transactionEditorValidationTransferDistinctAccounts;

  /// No description provided for @transactionEditorFieldAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get transactionEditorFieldAccount;

  /// No description provided for @transactionEditorFieldCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get transactionEditorFieldCategory;

  /// No description provided for @transactionEditorCategoryNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguna'**
  String get transactionEditorCategoryNone;

  /// No description provided for @transactionEditorCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría'**
  String get transactionEditorCategoryHint;

  /// No description provided for @transactionEditorValidationCategory.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría.'**
  String get transactionEditorValidationCategory;

  /// No description provided for @transactionEditorValidationCategoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos una categoría de ingreso o gasto (por ejemplo desde el menú).'**
  String get transactionEditorValidationCategoryEmpty;

  /// No description provided for @transactionEditorFieldType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get transactionEditorFieldType;

  /// No description provided for @transactionEditorTypeStandard.
  ///
  /// In es, this message translates to:
  /// **'Estándar'**
  String get transactionEditorTypeStandard;

  /// No description provided for @transactionEditorTypeAdjustment.
  ///
  /// In es, this message translates to:
  /// **'Ajuste'**
  String get transactionEditorTypeAdjustment;

  /// No description provided for @transactionEditorTypeTransferLeg.
  ///
  /// In es, this message translates to:
  /// **'Tramo de transferencia'**
  String get transactionEditorTypeTransferLeg;

  /// No description provided for @transactionEditorFieldMemo.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get transactionEditorFieldMemo;

  /// No description provided for @transactionEditorFieldTransferGroupId.
  ///
  /// In es, this message translates to:
  /// **'ID de grupo de transferencia'**
  String get transactionEditorFieldTransferGroupId;

  /// No description provided for @transactionEditorFieldLinkedTransactionId.
  ///
  /// In es, this message translates to:
  /// **'ID de transacción vinculado'**
  String get transactionEditorFieldLinkedTransactionId;

  /// No description provided for @transactionEditorSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get transactionEditorSave;

  /// No description provided for @transactionEditorDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar transacción'**
  String get transactionEditorDelete;

  /// No description provided for @transactionEditorValidationAmount.
  ///
  /// In es, this message translates to:
  /// **'Introduce un importe válido mayor que cero.'**
  String get transactionEditorValidationAmount;

  /// No description provided for @transactionEditorValidationAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta.'**
  String get transactionEditorValidationAccount;

  /// No description provided for @transactionEditorValidationDate.
  ///
  /// In es, this message translates to:
  /// **'Introduce una fecha válida (AAAA-MM-DD).'**
  String get transactionEditorValidationDate;

  /// No description provided for @transactionEditorDeleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar transacción?'**
  String get transactionEditorDeleteConfirmTitle;

  /// No description provided for @transactionEditorDeleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get transactionEditorDeleteConfirmBody;

  /// No description provided for @transactionEditorCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get transactionEditorCancel;

  /// No description provided for @transactionEditorDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get transactionEditorDeleteConfirm;

  /// No description provided for @transactionEditorErrorSave.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar. Inténtalo de nuevo.'**
  String get transactionEditorErrorSave;

  /// No description provided for @transactionEditorErrorDelete.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar. Inténtalo de nuevo.'**
  String get transactionEditorErrorDelete;

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
  /// **'Gastos fijos'**
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

  /// No description provided for @budgetsBillsLeftLabel.
  ///
  /// In es, this message translates to:
  /// **'Disponible para gastos fijos'**
  String get budgetsBillsLeftLabel;

  /// No description provided for @budgetsIncomeLeftLabel.
  ///
  /// In es, this message translates to:
  /// **'Por ganar'**
  String get budgetsIncomeLeftLabel;

  /// No description provided for @budgetsIncomeEarned.
  ///
  /// In es, this message translates to:
  /// **'Ingresado'**
  String get budgetsIncomeEarned;

  /// No description provided for @budgetsCategorySubtitleAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible · {amount}'**
  String budgetsCategorySubtitleAvailable(String amount);

  /// No description provided for @budgetsCompactBillsCaption.
  ///
  /// In es, this message translates to:
  /// **'Por pagar'**
  String get budgetsCompactBillsCaption;

  /// No description provided for @budgetsCompactEarningsCaption.
  ///
  /// In es, this message translates to:
  /// **'Por ganar'**
  String get budgetsCompactEarningsCaption;

  /// No description provided for @budgetsCompactAmountPaid.
  ///
  /// In es, this message translates to:
  /// **'{amount} pagado'**
  String budgetsCompactAmountPaid(String amount);

  /// No description provided for @budgetsCompactAmountEarned.
  ///
  /// In es, this message translates to:
  /// **'{amount} ingresado'**
  String budgetsCompactAmountEarned(String amount);

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

  /// No description provided for @actionRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get actionRetry;

  /// No description provided for @categoriesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay categorías.'**
  String get categoriesEmpty;

  /// No description provided for @categoriesAddCategory.
  ///
  /// In es, this message translates to:
  /// **'Añadir categoría'**
  String get categoriesAddCategory;

  /// No description provided for @accountsAddAccount.
  ///
  /// In es, this message translates to:
  /// **'Añadir cuenta'**
  String get accountsAddAccount;

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
