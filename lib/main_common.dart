import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'app/finko_app.dart';
import 'core/app_environment.dart';
import 'core/locale/app_environment_provider.dart';
import 'firebase_options_dev.dart' as dev_options;
import 'firebase_options_prod.dart' as prod_options;

export 'core/app_environment.dart' show AppEnvironment;

Future<void> bootstrapApp({required AppEnvironment environment}) async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final options = environment == AppEnvironment.dev
      ? dev_options.DefaultFirebaseOptions.currentPlatform
      : prod_options.DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: options);
  runApp(
    ProviderScope(
      overrides: [appEnvironmentProvider.overrideWithValue(environment)],
      child: const FinkoApp(),
    ),
  );
}
