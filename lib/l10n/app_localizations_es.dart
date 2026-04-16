// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Finko';

  @override
  String get dashboardTitle => 'Panel';

  @override
  String get dashboardHeadline => 'Resumen de tu dinero';

  @override
  String get openSettings => 'Ajustes';

  @override
  String get openOnboarding => 'Incorporación';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguageSection => 'Idioma';

  @override
  String get settingsLanguageLabel => 'Idioma de la app';

  @override
  String get localeSpanish => 'Español';

  @override
  String get localeEnglish => 'Inglés';

  @override
  String get onboardingStep1Title => 'Perfil y preferencias';

  @override
  String get onboardingDisplayNameLabel => 'Nombre para mostrar';

  @override
  String get onboardingTimezoneLabel => 'Zona horaria';

  @override
  String get onboardingThemeLabel => 'Tema';

  @override
  String get onboardingLocaleLabel => 'Idioma';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingBack => 'Atrás';

  @override
  String get onboardingCommit => 'Finalizar incorporación';

  @override
  String get onboardingCompleted => 'Incorporación completada.';

  @override
  String get onboardingStepProfileTitle => 'Perfil y preferencias';

  @override
  String get onboardingStepAccountsTitle => 'Cuentas';

  @override
  String get onboardingStepCategoriesTitle => 'Categorías';

  @override
  String get onboardingStepRecurringTitle => 'Ingresos recurrentes';

  @override
  String get onboardingStepBudgetsTitle => 'Presupuestos';

  @override
  String get onboardingStepProjectedTitle => 'Ahorro proyectado';

  @override
  String get onboardingStepMessagingTitle => 'Mensajería';

  @override
  String get onboardingStepReviewTitle => 'Revisar y finalizar';

  @override
  String get onboardingReviewIntro =>
      'Revisa lo siguiente. Toca finalizar para guardar tu configuración en Finko.';

  @override
  String get onboardingReviewPreferences => 'Tus elecciones';

  @override
  String get onboardingReviewSectionAccounts => 'Cuentas';

  @override
  String get onboardingReviewSectionCategories => 'Categorías';

  @override
  String onboardingReviewCategoriesCounts(int incomeCount, int expenseCount) {
    return 'Categorías de ingreso: $incomeCount · Categorías de gasto: $expenseCount';
  }

  @override
  String get onboardingReviewSectionRecurring => 'Ingresos recurrentes';

  @override
  String get onboardingReviewSectionBudgets => 'Presupuestos mensuales';

  @override
  String get onboardingReviewSectionProjected => 'Ahorro mensual proyectado';

  @override
  String get onboardingReviewSectionMessaging => 'Mensajería';

  @override
  String get onboardingReviewMessagingNone =>
      'Sin canales verificados (puedes conectar después).';

  @override
  String get onboardingReviewMessagingWhatsAppOk => 'WhatsApp verificado';

  @override
  String get onboardingReviewMessagingTelegramOk => 'Telegram verificado';

  @override
  String get onboardingReviewRecurringOff => 'No recurrente';

  @override
  String onboardingReviewBiweeklyDays(int day1, int day2) {
    return 'Pagos: días $day1 y $day2';
  }

  @override
  String get onboardingFirstPaydayLabel => 'Primer pago (día del mes)';

  @override
  String get onboardingSecondPaydayLabel => 'Segundo pago (día del mes)';

  @override
  String get onboardingStepCommitTitle => 'Guardando configuración';

  @override
  String get onboardingStepDoneTitle => 'Listo';

  @override
  String get onboardingAccountName => 'Nombre de la cuenta';

  @override
  String get onboardingAddAccount => 'Agregar cuenta';

  @override
  String get onboardingCategoryName => 'Nombre de la categoría';

  @override
  String get onboardingAddCategory => 'Agregar categoría';

  @override
  String get onboardingRecurringQuestion => 'Recurrente';

  @override
  String get onboardingNoIncomeCategories =>
      'Aún no hay categorías de ingreso.';

  @override
  String get onboardingExpectedIncome => 'Ingreso esperado';

  @override
  String get onboardingFixedExpenses => 'Gastos fijos';

  @override
  String get onboardingVariableExpenses => 'Gastos variables';

  @override
  String get onboardingProjectedSavings => 'Ahorro proyectado';

  @override
  String get onboardingMessagingIdentity => 'Teléfono o usuario de Telegram';

  @override
  String get onboardingRequestOtpWhatsApp => 'Solicitar OTP de WhatsApp';

  @override
  String get onboardingRequestOtpTelegram => 'Solicitar OTP de Telegram';

  @override
  String get onboardingOtpCode => 'Código OTP';

  @override
  String get onboardingVerifyWhatsApp => 'Verificar WhatsApp';

  @override
  String get onboardingVerifyTelegram => 'Verificar Telegram';

  @override
  String get onboardingRemindMeLater => 'Recordármelo después';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingLocaleSpanishMx => 'Español (México)';

  @override
  String get onboardingLocaleEnglishUs => 'Inglés (EE. UU.)';

  @override
  String get onboardingTimezoneMexicoSoutheast =>
      'México — Zona Sureste (UTC−5)';

  @override
  String get onboardingTimezoneMexicoCentral => 'México — Zona Centro (UTC−6)';

  @override
  String get onboardingTimezoneMexicoPacific =>
      'México — Zona Pacífico (UTC−7)';

  @override
  String get onboardingTimezoneMexicoNorthwest =>
      'México — Zona Noroeste (UTC−8)';

  @override
  String get onboardingTimezoneUsPacific => 'Estados Unidos — Pacífico';

  @override
  String get onboardingTimezoneUsMountain => 'Estados Unidos — Montaña';

  @override
  String get onboardingTimezoneUsEastern => 'Estados Unidos — Este';

  @override
  String get onboardingCategoryFixedExpenses => 'Gastos fijos';

  @override
  String get onboardingFixedExpensesInfoTooltip => 'Acerca de gastos fijos';

  @override
  String get onboardingFixedExpensesInfoTitle =>
      'Por qué gastos fijos está bloqueado';

  @override
  String get onboardingFixedExpensesInfoBody =>
      'Esta categoría está reservada para gastos que se mantienen parecidos cada mes—renta, servicios, mínimos de préstamo, suscripciones y obligaciones similares.\n\nFinko la incluye para que puedas presupuestar esos montos aparte del gasto variable del día a día. Durante la incorporación no se puede renombrar ni eliminar; solo defines cuánto presupuestas en el siguiente paso.';

  @override
  String get onboardingGotIt => 'Entendido';

  @override
  String get onboardingCategoryKindIncome => 'Ingreso';

  @override
  String get onboardingCategoryKindExpense => 'Gasto';

  @override
  String get onboardingPickIcon => 'Ícono';

  @override
  String get onboardingSectionColor => 'Color';

  @override
  String get onboardingCadenceWeekly => 'Semanal';

  @override
  String get onboardingWeekdayLabel => 'Día de la semana';

  @override
  String get onboardingCategoriesSectionIncome => 'Ingresos';

  @override
  String get onboardingCategoriesSectionExpense => 'Gastos';

  @override
  String get onboardingSaveCategory => 'Guardar categoría';

  @override
  String get onboardingEditCategory => 'Editar categoría';

  @override
  String get onboardingProjectedChartTitle =>
      'Cómo suma tu presupuesto mensual';

  @override
  String get onboardingSuggestedSalary => 'Salario';

  @override
  String get onboardingSuggestedFood => 'Comida';

  @override
  String get onboardingSuggestedTransport => 'Transporte';

  @override
  String get onboardingAddSuggested => 'Añadir sugerida';

  @override
  String get onboardingAccountTypeLabel => 'Tipo de cuenta';

  @override
  String get onboardingCurrencyLabel => 'Moneda';

  @override
  String get onboardingStartingBalanceLabel => 'Saldo inicial';

  @override
  String get onboardingSaveAccount => 'Guardar cuenta';

  @override
  String get onboardingEditAccount => 'Editar';

  @override
  String get onboardingRecurringAmountLabel => 'Monto (moneda principal)';

  @override
  String get onboardingDepositAccountLabel => 'Cuenta de depósito';

  @override
  String get onboardingCadenceLabel => 'Frecuencia';

  @override
  String get onboardingCadenceMonthly => 'Mensual';

  @override
  String get onboardingCadenceTwiceMonthly => 'Dos veces al mes';

  @override
  String get onboardingCadenceBiweekly => 'Quincenal (cada 14 días)';

  @override
  String get onboardingDayOfMonthLabel => 'Día del mes (1–31)';

  @override
  String get onboardingSecondDayLabel => 'Segundo día (1–31)';

  @override
  String get onboardingHintInvalidMonthDay =>
      'Si el día no existe en un mes, se usa el último día de ese mes.';

  @override
  String get onboardingValidationProfileNameRequired =>
      'Escribe un nombre para mostrar.';

  @override
  String get onboardingValidationProfileNameTooLong =>
      'El nombre para mostrar es demasiado largo.';

  @override
  String get onboardingValidationAccountsMinOne => 'Añade al menos una cuenta.';

  @override
  String get onboardingValidationAccountNameRequired =>
      'Cada cuenta necesita un nombre.';

  @override
  String get onboardingValidationCategoriesFixed =>
      'Falta la categoría de gastos fijos.';

  @override
  String get onboardingValidationRecurringAmount =>
      'Indica un monto recurrente mayor que cero.';

  @override
  String get onboardingValidationRecurringAccount =>
      'Elige una cuenta de depósito para el ingreso recurrente.';

  @override
  String get onboardingValidationRecurringDaysTwice =>
      'Elige ambos días de pago (días del mes) para ingreso quincenal.';

  @override
  String get onboardingValidationRecurringDayMonthly => 'Elige un día del mes.';

  @override
  String get onboardingValidationRecurringDayRange => 'Usa días entre 1 y 31.';

  @override
  String get onboardingValidationRecurringWeekday =>
      'Elige un día de la semana.';

  @override
  String get onboardingValidationBudgetMissing =>
      'Indica un presupuesto para cada categoría.';

  @override
  String get onboardingMessagingWhatsAppHint =>
      'WhatsApp: teléfono en E.164 (p. ej. +525512345678)';

  @override
  String get onboardingMessagingTelegramHint => 'Telegram: @usuario';

  @override
  String get accountTypeLoan => 'Préstamo';

  @override
  String get accountTypeMortgage => 'Hipoteca';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String environmentBanner(String env) {
    return '[$env]';
  }

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginEmailLabel => 'Correo electrónico';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginSignIn => 'Entrar';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get loginToggleSignUp => '¿No tienes cuenta? Crear cuenta';

  @override
  String get loginToggleSignIn => '¿Ya tienes cuenta? Entrar';

  @override
  String get loginGoogle => 'Continuar con Google';

  @override
  String get loginApple => 'Continuar con Apple';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginForgotPasswordMissingEmail =>
      'Escribe tu correo arriba para restablecer la contraseña';

  @override
  String get loginForgotPasswordSent =>
      'Se envió el correo para restablecer la contraseña. Revisa tu bandeja.';

  @override
  String get loginValidationRequired => 'Este campo es obligatorio';

  @override
  String get loginValidationEmail => 'Introduce un correo válido';

  @override
  String get loginValidationPasswordLength => 'Mínimo 6 caracteres';

  @override
  String get loginErrorInvalidCredential => 'Correo o contraseña incorrectos';

  @override
  String get loginErrorEmailInUse => 'Este correo ya está registrado';

  @override
  String get loginErrorGeneric => 'No se pudo completar el inicio de sesión';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String dashboardSignedInAs(String email) {
    return 'Sesión: $email';
  }

  @override
  String get navDashboard => 'Panel';

  @override
  String get navRecurring => 'Recurrente';

  @override
  String get navSpending => 'Gastos';

  @override
  String get navTransactions => 'Movimientos';

  @override
  String get navMore => 'Más';

  @override
  String get drawerCategories => 'Categorías';

  @override
  String get drawerAccounts => 'Cuentas';

  @override
  String get drawerUserPlaceholderName => 'Tú';

  @override
  String get drawerUserPlaceholderEmail => ' ';

  @override
  String get drawerUserPlaceholderInitial => 'F';

  @override
  String get recurringTitle => 'Recurrente';

  @override
  String get spendingTitle => 'Gastos';

  @override
  String get transactionsTitle => 'Movimientos';

  @override
  String get budgetsTitle => 'Presupuestos';

  @override
  String get categoriesTitle => 'Categorías';

  @override
  String get accountsTitle => 'Cuentas';

  @override
  String get metricNetWorth => 'Patrimonio neto';

  @override
  String get metricMonthlyExpense => 'Gasto del mes';

  @override
  String get metricDeltaStubUp => '+2,1 %';

  @override
  String get metricDeltaStubDown => '-1,0 %';

  @override
  String get accountTypeChecking => 'Debito';

  @override
  String get accountTypeCreditCard => 'Tarjetas de crédito';

  @override
  String get accountTypeSavings => 'Ahorros';

  @override
  String get accountTypeInvestment => 'Inversiones';

  @override
  String get netCashLabel => 'Efectivo neto';

  @override
  String get loansMortgageSectionTitle => 'Préstamos e hipoteca';

  @override
  String get dashboardAccountsHeading => 'Cuentas';

  @override
  String get dashboardUpcomingHeading => 'Próximos';

  @override
  String get dashboardRecentHeading => 'Movimientos recientes';

  @override
  String get seeMore => 'Ver más';

  @override
  String get leftForSpending => 'Disponible para gastar';

  @override
  String get thisMonthsBudget => 'Presupuesto del mes';

  @override
  String get upcomingToday => 'Hoy';

  @override
  String get upcomingTomorrow => 'Mañana';

  @override
  String upcomingInDays(int count) {
    return '$count días';
  }

  @override
  String get emptyNoAccounts => 'Aún no hay cuentas.';

  @override
  String get emptyNoTransactions => 'Aún no hay movimientos.';

  @override
  String get emptyNoUpcoming => 'No hay próximos movimientos.';

  @override
  String get emptyNoMonthlyTotals =>
      'Aún no hay totales del mes — añade un movimiento.';

  @override
  String get spendingPeriodWeek => 'Semana';

  @override
  String get spendingPeriodMonth => 'Mes';

  @override
  String get spendingPeriodQuarter => 'Trimestre';

  @override
  String get spendingPeriodYear => 'Año';

  @override
  String get spendingIncome => 'Ingresos';

  @override
  String get spendingExpense => 'Gastos';

  @override
  String get spendingTotalSpend => 'Gasto total';

  @override
  String spendingInPeriod(String period) {
    return 'En $period';
  }

  @override
  String get spendingTopTransactions => 'Principales movimientos';

  @override
  String get transactionsSearchHint => 'Buscar movimientos';

  @override
  String get budgetsThisMonth => 'Este mes';

  @override
  String get budgetsPaceSlashDay => '/día';

  @override
  String budgetsDaysRemainingInMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días restantes',
      one: '1 día restante',
      zero: '0 días restantes',
    );
    return '$_temp0';
  }

  @override
  String budgetsSpendingPace(String paceWithDayUnit, String daysPhrase) {
    return '$paceWithDayUnit · $daysPhrase';
  }

  @override
  String get budgetsSpendingTitle => 'Gasto';

  @override
  String get budgetsLeftToSpend => 'disponible para gastar';

  @override
  String get budgetsSpent => 'Gastado';

  @override
  String get budgetsBudgeted => 'Presupuestado';

  @override
  String get budgetsBillsUtilities => 'Facturas y servicios';

  @override
  String get budgetsEarnings => 'Ingresos';

  @override
  String get budgetsProjectedSavings => 'Ahorro previsto';

  @override
  String budgetsOfTarget(String amount) {
    return 'De $amount objetivo';
  }

  @override
  String get budgetsCategoryBudgets => 'Presupuestos por categoría';

  @override
  String get recurringThisWeek => 'Esta semana';

  @override
  String get recurringNextWeek => 'Próxima semana';

  @override
  String get recurringComingUp => 'Próximamente';

  @override
  String get recurringDueSoon => 'Pronto';

  @override
  String get recurringComingLater => 'Más adelante';

  @override
  String get categoriesEmpty => 'Aún no hay categorías en los datos del mes.';

  @override
  String get accountsListSubtitle => 'Toca una cuenta cuando existan detalles.';
}
