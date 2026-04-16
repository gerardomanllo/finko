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
  String get accountTypeChecking => 'Cuenta corriente';

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
