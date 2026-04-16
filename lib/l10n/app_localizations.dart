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

  /// No description provided for @loginMessagingNote.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp y Telegram no son métodos de inicio de sesión. Conéctalos en Ajustes.'**
  String get loginMessagingNote;

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
