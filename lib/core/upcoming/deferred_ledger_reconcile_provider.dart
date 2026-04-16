import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_functions_provider.dart';
import 'deferred_ledger_reconcile_service.dart';

final deferredLedgerReconcileServiceProvider =
    Provider<DeferredLedgerReconcileService>(
  (ref) => DeferredLedgerReconcileService(
    functions: ref.watch(firebaseFunctionsProvider),
  ),
);
