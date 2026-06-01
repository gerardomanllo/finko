import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finko/core/data/models/user_profile.dart';
import 'package:finko/core/data/providers/finko_stream_providers.dart';
import 'package:finko/features/product_tutorial/application/show_tutorial_in_drawer.dart';

void main() {
  test('showTutorialInDrawer true on day 0 through day 14', () async {
    final container = ProviderContainer(
      overrides: [
        todayYyyyMmDdProvider.overrideWithValue('2026-05-25'),
        userProfileStreamProvider.overrideWith(
          (ref) => Stream.value(
            UserProfile(
              uid: 'u1',
              createdAt: DateTime.utc(2026, 5, 25),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(userProfileStreamProvider.future);
    expect(container.read(showTutorialInDrawerProvider), isTrue);
  });

  test('showTutorialInDrawer false after 15 days', () async {
    final container = ProviderContainer(
      overrides: [
        todayYyyyMmDdProvider.overrideWithValue('2026-05-26'),
        userProfileStreamProvider.overrideWith(
          (ref) => Stream.value(
            UserProfile(
              uid: 'u1',
              createdAt: DateTime.utc(2026, 5, 11),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(userProfileStreamProvider.future);
    expect(container.read(showTutorialInDrawerProvider), isFalse);
  });

  test('showTutorialInDrawer false when createdAt missing', () async {
    final container = ProviderContainer(
      overrides: [
        todayYyyyMmDdProvider.overrideWithValue('2026-05-25'),
        userProfileStreamProvider.overrideWith(
          (ref) => Stream.value(const UserProfile(uid: 'u1')),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(userProfileStreamProvider.future);
    expect(container.read(showTutorialInDrawerProvider), isFalse);
  });
}
