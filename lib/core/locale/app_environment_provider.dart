import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_environment.dart';

/// Overridden in [bootstrapApp] with the active flavor (dev/prod).
final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.dev,
);
