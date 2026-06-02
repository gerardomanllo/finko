import '../app_environment.dart';

/// OAuth client IDs from Firebase / `google-services.json` (public; not secret).
abstract final class GoogleAuthConfig {
  /// Web client ID — required on Android so Firebase receives an `idToken`.
  static String webClientId(AppEnvironment env) => switch (env) {
    AppEnvironment.dev =>
      '654834705056-iedqngb7qccitppj6dd8p1h06o6nbfui.apps.googleusercontent.com',
    AppEnvironment.prod =>
      '34402393511-9aptvql5ad06uo1vapmtut38gcl734ql.apps.googleusercontent.com',
  };

  /// iOS client ID — matches flavor `GoogleService-Info.plist` `CLIENT_ID`.
  static String iosClientId(AppEnvironment env) => switch (env) {
    AppEnvironment.dev =>
      '654834705056-9ukst9cus177f9o33e4up9eolth1206v.apps.googleusercontent.com',
    AppEnvironment.prod =>
      '34402393511-c944tnqagr0kfsuvpcvplsnnn1mc65ss.apps.googleusercontent.com',
  };
}
