import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_functions_provider.dart';

class AccountDeletionService {
  AccountDeletionService(this._functions);

  final FirebaseFunctions _functions;

  Future<void> deleteMyAccount() async {
    final callable = _functions.httpsCallable('deleteMyAccount');
    await callable.call<Map<String, dynamic>>(<String, dynamic>{});
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>(
  (ref) => AccountDeletionService(ref.watch(firebaseFunctionsProvider)),
);
