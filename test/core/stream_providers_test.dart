import 'package:finko/core/auth/firebase_auth_providers.dart';
import 'package:finko/core/data/providers/finko_stream_providers.dart';
import 'package:finko/core/data/repositories/firestore_data_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_firestore_data_repository.dart';

void main() {
  test('accountsStreamProvider emits empty list when uid is null', () async {
    final container = ProviderContainer(
      overrides: [
        authUidProvider.overrideWith((ref) => null),
        firestoreDataRepositoryProvider.overrideWithValue(
          FakeFirestoreDataRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(accountsStreamProvider, (previous, next) {});
    await Future<void>.delayed(Duration.zero);
    final async = container.read(accountsStreamProvider);
    expect(async.hasValue, isTrue);
    expect(async.value, <dynamic>[]);
    sub.close();
  });
}
