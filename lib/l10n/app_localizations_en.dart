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
}
