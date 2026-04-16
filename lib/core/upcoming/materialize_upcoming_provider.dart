import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_functions_provider.dart';
import 'materialize_upcoming_service.dart';

final materializeUpcomingServiceProvider = Provider<MaterializeUpcomingService>(
  (ref) => MaterializeUpcomingService(
    functions: ref.watch(firebaseFunctionsProvider),
  ),
);
