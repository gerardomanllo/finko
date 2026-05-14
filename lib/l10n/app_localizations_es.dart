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
  String get onboardingMainCurrencyLabel => 'Moneda principal';

  @override
  String get onboardingAccountNameCash => 'Efectivo';

  @override
  String get onboardingCreditLimitLabel => 'Límite de crédito total';

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
    return 'SIN AHORRO - $amount SOBRE INGRESOS';
  }

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
  String get onboardingRequestOtpTelegram => 'Vincular Telegram';

  @override
  String get onboardingOtpCode => 'Código OTP';

  @override
  String get messagingTelegramLinkInstructions =>
      'Abre el bot de Finko en Telegram desde la app, pulsa Iniciar y luego pulsa Listo aquí cuando la app indique que Telegram quedó vinculado.';

  @override
  String get messagingTelegramOpenBot => 'Abrir Telegram';

  @override
  String messagingOtpDevCodeSnack(String code) {
    return 'Compilación de desarrollo: tu OTP es $code';
  }

  @override
  String get messagingTelegramIntro =>
      'Vincula tu cuenta de Telegram con Finko. Elige teléfono (formato internacional) o tu usuario @ de Telegram y sigue los pasos.';

  @override
  String get messagingTelegramLinkMethodLabel =>
      '¿Cómo identificamos tu cuenta de Telegram?';

  @override
  String get messagingTelegramLinkMethodPhone => 'Teléfono';

  @override
  String get messagingTelegramLinkMethodUsername => 'Usuario';

  @override
  String get messagingTelegramCountryCodeLabel => 'Código de país';

  @override
  String get messagingTelegramPhoneLabel => 'Número de teléfono';

  @override
  String get messagingTelegramPhoneHint => 'Solo dígitos (sin espacios)';

  @override
  String get messagingTelegramUsernameLabel => 'Usuario de Telegram';

  @override
  String get messagingTelegramNext => 'Siguiente';

  @override
  String get messagingTelegramStatusRegistering =>
      'Registrando teléfono / usuario en Finko…';

  @override
  String get messagingTelegramStatusPreparingTelegram =>
      'Preparando enlace seguro para Telegram…';

  @override
  String get messagingTelegramStatusWaitingForBot =>
      'Esperando que abras Telegram y pulses Iniciar en el bot de Finko…';

  @override
  String get messagingTelegramAwaitingBotBody =>
      'Detectaremos el enlace automáticamente. Si no pasa nada tras pulsar Iniciar, vuelve aquí y confirma el código de país y el número (o el usuario).';

  @override
  String get messagingTelegramListeningFirestore =>
      'Escuchando el documento de enlace en Firestore para chat_id…';

  @override
  String get messagingTelegramStatusLinkDetected =>
      'Chat de Telegram vinculado correctamente.';

  @override
  String get messagingTelegramLinkedTitle => 'Vinculado';

  @override
  String get messagingTelegramLinkedBody =>
      'Tu cuenta de Telegram quedó conectada con Finko. Pulsa Listo para continuar o cierra y termina más tarde.';

  @override
  String get messagingTelegramDone => 'Listo';

  @override
  String get messagingTelegramClose => 'Cerrar';

  @override
  String get messagingTelegramPreparingHint =>
      'Hablando con Cloud Functions y Firestore. En depuración, revisa el panel de trazas abajo.';

  @override
  String get messagingTelegramLinkFailedTitle => 'Algo salió mal';

  @override
  String get messagingTelegramRetry => 'Intentar de nuevo';

  @override
  String get messagingTelegramErrPhoneTooShort =>
      'Escribe más dígitos en tu número.';

  @override
  String get messagingTelegramErrPhoneFormat =>
      'Ese número no parece un formato internacional válido (+país…).';

  @override
  String get messagingTelegramErrUsernameTooShort =>
      'Escribe un usuario de Telegram válido (al menos 5 caracteres tras @).';

  @override
  String get messagingTelegramErrStepServer => 'Configuración del servidor';

  @override
  String get messagingTelegramErrNoDeepLink =>
      'La app no recibió el enlace profundo de Telegram. Revisa TELEGRAM_BOT_USERNAME y el despliegue de funciones.';

  @override
  String get messagingTelegramErrUnexpectedResponse =>
      'Respuesta inesperada del servidor. Inténtalo de nuevo o actualiza la app.';

  @override
  String get messagingTelegramErrStepTimeout => 'Tiempo de espera agotado';

  @override
  String get messagingTelegramTimeoutBody =>
      'Abre Telegram con el botón, pulsa Iniciar en el bot e inténtalo de nuevo. Los enlaces caducan en unos minutos.';

  @override
  String get messagingTelegramErrStepCallable => 'Error en Cloud Function';

  @override
  String get messagingTelegramErrStepFirestore =>
      'Error del listener de Firestore';

  @override
  String get messagingTelegramErrStepUnknown => 'Error inesperado';

  @override
  String get messagingTelegramErrLaunchTelegram =>
      'No se pudo abrir Telegram en este dispositivo.';

  @override
  String get messagingTelegramErrStillNeedsBot =>
      'El servidor aún pide abrir el bot. Pulsa Iniciar en Telegram y luego Continuar otra vez.';

  @override
  String get messagingTelegramErrVerify => 'La verificación falló';

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
  String get themeAutomatic => 'Automático';

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
  String get settingsAppearanceSection => 'Apariencia';

  @override
  String get settingsThemeLabel => 'Tema de color';

  @override
  String get settingsMembershipSection => 'Membresía';

  @override
  String get settingsManagePlan => 'Administrar tu plan';

  @override
  String get settingsManagePlanSubtitle =>
      'Abre la facturación de Stripe (próximamente).';

  @override
  String get settingsComingSoonLabel => 'Próximamente';

  @override
  String get settingsMessagingSection => 'Mensajería';

  @override
  String get settingsMessagingWhatsApp => 'WhatsApp';

  @override
  String get settingsMessagingTelegram => 'Telegram';

  @override
  String get settingsMessagingStatusConnected => 'Conectado';

  @override
  String get settingsMessagingStatusNotConnected => 'Sin conectar';

  @override
  String settingsMessagingConnectedWhatsAppDetail(String phone) {
    return 'Número de WhatsApp: $phone';
  }

  @override
  String settingsMessagingConnectedTelegramDetail(String username) {
    return 'Telegram: $username';
  }

  @override
  String settingsMessagingVerifiedOn(String date) {
    return 'Verificado el $date';
  }

  @override
  String get settingsMessagingDisconnect => 'Desconectar';

  @override
  String get settingsMessagingDisconnectConfirmTitle =>
      '¿Desconectar este canal?';

  @override
  String get settingsMessagingDisconnectConfirmBody =>
      'Puedes volver a conectarlo cuando quieras desde Ajustes.';

  @override
  String get settingsMessagingDisconnectConfirmCta => 'Desconectar';

  @override
  String get settingsMessagingDisconnectCancel => 'Cancelar';

  @override
  String get settingsMessagingTelegramBotDefaults => 'Valores del bot';

  @override
  String get settingsTelegramBotDefaultsTitle => 'Valores del bot de Telegram';

  @override
  String get settingsTelegramBotDefaultsSubtitle =>
      'Atajos opcionales al usar el bot de Finko (cuenta, categorías e idioma de respuesta).';

  @override
  String get settingsTelegramBotDefaultsLocale => 'Idioma del bot';

  @override
  String get settingsTelegramBotDefaultsLocaleFollow => 'Igual que Telegram';

  @override
  String get settingsTelegramBotDefaultsLocaleEs => 'Español';

  @override
  String get settingsTelegramBotDefaultsLocaleEn => 'Inglés';

  @override
  String get settingsTelegramBotDefaultsAccount => 'Cuenta predeterminada';

  @override
  String get settingsTelegramBotDefaultsExpenseCategory => 'Categoría de gasto';

  @override
  String get settingsTelegramBotDefaultsIncomeCategory =>
      'Categoría de ingreso';

  @override
  String get settingsTelegramBotDefaultsNone => 'Ninguna';

  @override
  String get settingsTelegramBotDefaultsSave => 'Guardar';

  @override
  String get settingsTelegramBotDefaultsClear => 'Borrar valores';

  @override
  String get settingsErrorSave => 'No se pudo guardar. Intenta de nuevo.';

  @override
  String dashboardSignedInAs(String email) {
    return 'Sesión: $email';
  }

  @override
  String get navDashboard => 'Panel';

  @override
  String get navRecurring => 'Recurrente';

  @override
  String get navNewTransaction => 'Nuevo';

  @override
  String get navSpending => 'Gastos';

  @override
  String get navTransactions => 'Transacciones';

  @override
  String get openShellMenu => 'Abrir menú';

  @override
  String get newTransactionSheetTitle => 'Nueva transacción';

  @override
  String get newTransactionSheetBody => 'Añade una transacción';

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
  String get transactionsTitle => 'Transacciones';

  @override
  String get budgetsTitle => 'Presupuestos';

  @override
  String get categoryEditorDeleteCategory => 'Eliminar categoría…';

  @override
  String get categoryEditorMonthlyBudgetLabel =>
      'Presupuesto mensual (moneda principal)';

  @override
  String get accountEditorDeleteAccount => 'Eliminar cuenta…';

  @override
  String categoryDeleteCascadeTitle(String name) {
    return '¿Eliminar “$name” y todos los datos relacionados?';
  }

  @override
  String categoryDeleteCascadeBody(
    int transactions,
    int recurring,
    int upcoming,
  ) {
    return 'Se eliminarán $transactions transacciones, $recurring reglas recurrentes, $upcoming próximos y la fila de presupuesto de esta categoría. No se puede deshacer.';
  }

  @override
  String accountDeleteCascadeTitle(String name) {
    return '¿Eliminar la cuenta “$name” y todos los datos relacionados?';
  }

  @override
  String accountDeleteCascadeBody(
    int transactions,
    int recurring,
    int upcoming,
  ) {
    return 'Se eliminarán $transactions transacciones (incluidos tramos de transferencia emparejados), $recurring recurrentes, $upcoming próximos y luego la cuenta. No se puede deshacer.';
  }

  @override
  String get deleteCascadeConfirm => 'Eliminar todo';

  @override
  String get deleteCascadeSuccess => 'Eliminado.';

  @override
  String get categoriesTitle => 'Categorías';

  @override
  String get accountsTitle => 'Cuentas';

  @override
  String get metricNetWorth => 'Patrimonio neto';

  @override
  String get metricNetWorthSeeAccountsFooter => 'Ver mis cuentas';

  @override
  String get metricMonthlyExpenseSeeSpendingFooter => 'Ver mis gastos';

  @override
  String get metricMonthlyExpense => 'Gasto del mes';

  @override
  String get metricDeltaStubUp => '+2,1 %';

  @override
  String get metricDeltaStubDown => '-1,0 %';

  @override
  String get accountTypeChecking => 'Debito';

  @override
  String get accountTypeCash => 'Efectivo';

  @override
  String get accountTypeCreditCard => 'Tarjetas de crédito';

  @override
  String get accountTypeSavings => 'Ahorros';

  @override
  String get accountTypeInvestment => 'Inversiones';

  @override
  String get netCashLabel => 'Efectivo neto';

  @override
  String get dashboardNetCashInfoTooltip => 'Cómo se calcula el efectivo neto';

  @override
  String get dashboardNetCashInfoTitle => 'Efectivo neto';

  @override
  String get dashboardNetCashInfoBody =>
      'El efectivo neto es un total con signo para las cuentas que cuentan como flujo de efectivo líquido: se suman los saldos de cuentas de activo (por ejemplo, débito) y se restan los importes adeudados en cuentas de pasivo (por ejemplo, tarjetas de crédito).\n\nUna cuenta entra cuando tiene activada la opción “Incluir en efectivo neto”. Si nunca se definió, por defecto se incluyen cuentas de débito y tarjetas de crédito; no se incluyen ahorros, inversiones, préstamos ni hipotecas.\n\nPara cada cuenta incluida, Finko usa el saldo en tu moneda principal cuando existe; si no, el saldo en la moneda de esa cuenta.';

  @override
  String get loansMortgageSectionTitle => 'Préstamos e hipoteca';

  @override
  String get dashboardAccountsHeading => 'Cuentas';

  @override
  String get dashboardUpcomingHeading => 'Próximos';

  @override
  String get dashboardUpcomingSeeAll => 'Ver todos los próximos';

  @override
  String get dashboardRecentHeading => 'Transacciones recientes';

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
  String get emptyNoTransactions => 'Aún no hay transacciones.';

  @override
  String get emptyNoUpcoming => 'No hay próximas transacciones.';

  @override
  String get emptyNoMonthlyTotals =>
      'Aún no hay totales del mes — añade un transacción.';

  @override
  String get summaryMonthTotalLabel => 'Este mes';

  @override
  String get summaryRecentTransactionsLabel => 'Transacciones recientes';

  @override
  String get summaryNoTransactionsThisMonth => 'No hay transacciones este mes.';

  @override
  String summaryYearMonthHeading(String yearMonth) {
    return '$yearMonth';
  }

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
  String get spendingTotalSpendIn => 'Gasto total';

  @override
  String get spendingFixedExpenses => 'Gastos fijos';

  @override
  String get spendingVariableExpenses => 'Gastos variables';

  @override
  String get spendingUncategorized => 'Sin categoría';

  @override
  String get spendingStripEmpty =>
      'Aún no hay períodos con transacciones en este rango.';

  @override
  String spendingInPeriod(String period) {
    return 'En $period';
  }

  @override
  String get spendingTopTransactions => 'Gastos más grandes';

  @override
  String get transactionsSearchHint => 'Buscar transacciones';

  @override
  String get transactionsFilterAll => 'Todos los tipos';

  @override
  String get transactionsFilterStandard => 'Estándar';

  @override
  String get transactionsFilterTransfer => 'Transferencia';

  @override
  String get transactionsFilterAdjustment => 'Ajuste';

  @override
  String get transactionsFilterSheetTitle => 'Filtrar por tipo';

  @override
  String get transactionsSearchSearchingHistory =>
      'No aparece en lo cargado. Buscando en todo el historial…';

  @override
  String get transactionsSearchHistoryLimitReached =>
      'Sin coincidencias en esta parte del historial. Prueba un término más específico.';

  @override
  String get transactionsSearchNoMatches =>
      'No hay transacciones que coincidan.';

  @override
  String get transactionEditorSheetEditTitle => 'Editar transacción';

  @override
  String get transactionEditorFieldDate => 'Fecha';

  @override
  String get transactionEditorFieldAmount => 'Importe';

  @override
  String get transactionEditorFieldTransferAmountOut => 'Importe enviado';

  @override
  String get transactionEditorFieldTransferAmountIn => 'Importe recibido';

  @override
  String get transactionEditorFieldDirection => 'Dirección';

  @override
  String get transactionEditorDirectionIn => 'Ingreso';

  @override
  String get transactionEditorDirectionOut => 'Gasto';

  @override
  String get transactionEditorEntryTransfer => 'Transferencia';

  @override
  String get transactionEditorModeRecurring => 'Recurrente';

  @override
  String get newTransactionRecurringHint =>
      'Guarda el movimiento y elige la frecuencia. Puedes cancelar la programación y quedarte solo con este registro.';

  @override
  String get transactionEditorSaveAndMakeRecurring =>
      'Guardar y hacer recurrente';

  @override
  String get transactionEditorFieldFromAccount => 'Cuenta origen';

  @override
  String get transactionEditorFieldToAccount => 'Cuenta destino';

  @override
  String get transactionEditorValidationFromAccount =>
      'Elige la cuenta desde la que sale el dinero.';

  @override
  String get transactionEditorValidationToAccount =>
      'Elige la cuenta a la que entra el dinero.';

  @override
  String get transactionEditorValidationTransferSameCurrency =>
      'Ambas cuentas deben tener la misma moneda para una transferencia.';

  @override
  String get transactionEditorValidationTransferDistinctAccounts =>
      'Elige dos cuentas distintas.';

  @override
  String get transactionEditorFieldAccount => 'Cuenta';

  @override
  String get transactionEditorFieldCategory => 'Categoría';

  @override
  String get transactionEditorCategoryNone => 'Ninguna';

  @override
  String get transactionEditorCategoryHint => 'Elige una categoría';

  @override
  String get transactionEditorValidationCategory => 'Elige una categoría.';

  @override
  String get transactionEditorValidationCategoryEmpty =>
      'Añade al menos una categoría de ingreso o gasto (por ejemplo desde el menú).';

  @override
  String get transactionEditorFieldType => 'Tipo';

  @override
  String get transactionEditorTypeStandard => 'Estándar';

  @override
  String get transactionEditorTypeAdjustment => 'Ajuste';

  @override
  String get transactionEditorTypeTransferLeg => 'Tramo de transferencia';

  @override
  String get transactionEditorFieldMemo => 'Nota';

  @override
  String get transactionEditorFieldTransferGroupId =>
      'ID de grupo de transferencia';

  @override
  String get transactionEditorFieldLinkedTransactionId =>
      'ID de transacción vinculado';

  @override
  String get transactionEditorSave => 'Guardar';

  @override
  String get transactionEditorDelete => 'Eliminar transacción';

  @override
  String get transactionEditorValidationAmount =>
      'Introduce un importe válido mayor que cero.';

  @override
  String get transactionEditorValidationAccount => 'Elige una cuenta.';

  @override
  String get transactionEditorValidationDate =>
      'Introduce una fecha válida (AAAA-MM-DD).';

  @override
  String get transactionEditorDeleteConfirmTitle => '¿Eliminar transacción?';

  @override
  String get transactionEditorDeleteConfirmBody =>
      'Esta acción no se puede deshacer.';

  @override
  String get transactionEditorCancel => 'Cancelar';

  @override
  String get transactionEditorDeleteConfirm => 'Eliminar';

  @override
  String get transactionEditorErrorSave =>
      'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get transactionEditorErrorDelete =>
      'No se pudo eliminar. Inténtalo de nuevo.';

  @override
  String get transactionEditorMakeRecurring => 'Hacer recurrente';

  @override
  String get recurringFromTxTitle => 'Crear regla recurrente';

  @override
  String get recurringFromTxCadence => 'Con qué frecuencia';

  @override
  String get recurringFromTxCadenceMonthly => 'Mensual';

  @override
  String get recurringFromTxCadenceTwiceMonthly => 'Dos veces al mes';

  @override
  String get recurringFromTxCadenceBiweekly => 'Cada dos semanas';

  @override
  String get recurringFromTxCadenceWeekly => 'Semanal';

  @override
  String get recurringFromTxDayOfMonth => 'Día del mes (1–31)';

  @override
  String get recurringFromTxSecondDay => 'Segundo día (1–31)';

  @override
  String get recurringFromTxWeekday => 'Día de la semana';

  @override
  String get recurringFromTxSubmit => 'Crear regla';

  @override
  String get recurringFromTxSuccess => 'Regla recurrente creada.';

  @override
  String get recurringFromTxError => 'No se pudo crear la regla recurrente.';

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
  String get budgetsBillsUtilities => 'Gastos fijos';

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
  String get budgetsBillsLeftLabel => 'Disponible para gastos fijos';

  @override
  String get budgetsIncomeLeftLabel => 'Por ganar';

  @override
  String get budgetsIncomeEarned => 'Ingresado';

  @override
  String budgetsCategorySubtitleAvailable(String amount) {
    return 'Disponible · $amount';
  }

  @override
  String get budgetsCompactBillsCaption => 'Por pagar';

  @override
  String get budgetsCompactEarningsCaption => 'Por ganar';

  @override
  String budgetsCompactAmountPaid(String amount) {
    return '$amount pagado';
  }

  @override
  String budgetsCompactAmountEarned(String amount) {
    return '$amount ingresado';
  }

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
  String get actionRetry => 'Reintentar';

  @override
  String get categoriesEmpty => 'Aún no hay categorías.';

  @override
  String get categoriesAddCategory => 'Añadir categoría';

  @override
  String get accountsAddAccount => 'Añadir cuenta';

  @override
  String get accountsListSubtitle => 'Toca una cuenta cuando existan detalles.';
}
