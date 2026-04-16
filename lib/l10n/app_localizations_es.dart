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
  String get loginMessagingNote =>
      'WhatsApp y Telegram no son métodos de inicio de sesión. Conéctalos en Ajustes.';

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
}
