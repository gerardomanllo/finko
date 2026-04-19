import 'package:finko/core/auth/firebase_auth_providers.dart';
import 'package:finko/core/data/models/user_profile.dart';
import 'package:finko/core/data/providers/finko_stream_providers.dart';
import 'package:finko/core/data/repositories/firestore_data_repository.dart';
import 'package:finko/core/refresh/ledger_aware_app_refresh.dart';
import 'package:finko/core/upcoming/deferred_ledger_reconcile_provider.dart';
import 'package:finko/core/upcoming/deferred_ledger_reconcile_service.dart';
import 'package:finko/core/upcoming/materialize_upcoming_provider.dart';
import 'package:finko/core/upcoming/materialize_upcoming_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_firestore_data_repository.dart';

void main() {
  group('LedgerAwareAppRefresh.needsReconcileFromProfile', () {
    test('true when either timestamp is null', () {
      expect(
        LedgerAwareAppRefresh.needsReconcileFromProfile(null, null),
        isTrue,
      );
      expect(
        LedgerAwareAppRefresh.needsReconcileFromProfile(
          DateTime.utc(2026),
          null,
        ),
        isTrue,
      );
      expect(
        LedgerAwareAppRefresh.needsReconcileFromProfile(
          null,
          DateTime.utc(2026),
        ),
        isTrue,
      );
    });

    test('true when ledger sources newer than aggregate completion', () {
      expect(
        LedgerAwareAppRefresh.needsReconcileFromProfile(
          DateTime.utc(2026, 4, 10),
          DateTime.utc(2026, 4, 11),
        ),
        isTrue,
      );
    });

    test('false when aggregate completion is same or after ledger change', () {
      expect(
        LedgerAwareAppRefresh.needsReconcileFromProfile(
          DateTime.utc(2026, 4, 11),
          DateTime.utc(2026, 4, 11),
        ),
        isFalse,
      );
      expect(
        LedgerAwareAppRefresh.needsReconcileFromProfile(
          DateTime.utc(2026, 4, 12),
          DateTime.utc(2026, 4, 11),
        ),
        isFalse,
      );
    });
  });

  group('LedgerAwareAppRefresh.runPullToRefresh', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    /// MaterialApp supplies [Directionality] for Material buttons in tests.
    Widget materializedProviderScope({
      required List<Override> overrides,
      required Widget child,
    }) {
      return MaterialApp(
        home: ProviderScope(overrides: overrides, child: child),
      );
    }

    testWidgets('signed out returns signedOut without callables', (
      tester,
    ) async {
      var mat = 0;
      var rec = 0;
      LedgerAwareRefreshResult? result;

      await tester.pumpWidget(
        materializedProviderScope(
          overrides: [
            authUidProvider.overrideWith((ref) => null),
            firestoreDataRepositoryProvider.overrideWithValue(
              FakeFirestoreDataRepository(),
            ),
            nowProvider.overrideWith((ref) => DateTime.utc(2026, 4, 18)),
            userProfileStreamProvider.overrideWith(
              (ref) => Stream<UserProfile?>.value(null),
            ),
            materializeUpcomingServiceProvider.overrideWithValue(
              MaterializeUpcomingService(
                callable: (_) async {
                  mat++;
                },
                now: () => DateTime.utc(2026, 4, 18),
              ),
            ),
            deferredLedgerReconcileServiceProvider.overrideWithValue(
              DeferredLedgerReconcileService(
                callable: (_) async {
                  rec++;
                },
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return TextButton(
                onPressed: () async {
                  result = await ref
                      .read(ledgerAwareAppRefreshProvider)
                      .runPullToRefresh(ref);
                },
                child: const Text('run'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(result, LedgerAwareRefreshResult.signedOut);
      expect(mat, 0);
      expect(rec, 0);
    });

    testWidgets('throttled skips callables and invalidation path', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'finko_ledger_refresh_last_wall_ms_test-uid':
            DateTime.now().millisecondsSinceEpoch,
      });

      var mat = 0;
      var rec = 0;
      LedgerAwareRefreshResult? result;

      await tester.pumpWidget(
        materializedProviderScope(
          overrides: [
            authUidProvider.overrideWith((ref) => 'test-uid'),
            firestoreDataRepositoryProvider.overrideWithValue(
              FakeFirestoreDataRepository(),
            ),
            nowProvider.overrideWith((ref) => DateTime.utc(2026, 4, 18)),
            userProfileStreamProvider.overrideWith(
              (ref) => Stream.value(
                const UserProfile(uid: 'test-uid', timezone: 'Etc/UTC'),
              ),
            ),
            materializeUpcomingServiceProvider.overrideWithValue(
              MaterializeUpcomingService(
                callable: (_) async {
                  mat++;
                },
                now: () => DateTime.utc(2026, 4, 18),
              ),
            ),
            deferredLedgerReconcileServiceProvider.overrideWithValue(
              DeferredLedgerReconcileService(
                callable: (_) async {
                  rec++;
                },
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return TextButton(
                onPressed: () async {
                  result = await ref
                      .read(ledgerAwareAppRefreshProvider)
                      .runPullToRefresh(ref);
                },
                child: const Text('run'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(result, LedgerAwareRefreshResult.throttled);
      expect(mat, 0);
      expect(rec, 0);
    });

    testWidgets('clean profile skips reconcile but still materializes', (
      tester,
    ) async {
      var mat = 0;
      var rec = 0;
      final repo = FakeFirestoreDataRepository(
        userProfileForFetchSync: UserProfile(
          uid: 'test-uid',
          timezone: 'Etc/UTC',
          aggregateLastCompletedAt: DateTime.utc(2026, 4, 18),
          ledgerSourcesLastChangedAt: DateTime.utc(2026, 4, 17),
        ),
      );

      await tester.pumpWidget(
        materializedProviderScope(
          overrides: [
            authUidProvider.overrideWith((ref) => 'test-uid'),
            firestoreDataRepositoryProvider.overrideWithValue(repo),
            nowProvider.overrideWith((ref) => DateTime.utc(2026, 4, 18, 12)),
            userProfileStreamProvider.overrideWith(
              (ref) => Stream.value(
                const UserProfile(uid: 'test-uid', timezone: 'Etc/UTC'),
              ),
            ),
            materializeUpcomingServiceProvider.overrideWithValue(
              MaterializeUpcomingService(
                callable: (_) async {
                  mat++;
                },
                now: () => DateTime.utc(2026, 4, 18),
              ),
            ),
            deferredLedgerReconcileServiceProvider.overrideWithValue(
              DeferredLedgerReconcileService(
                callable: (_) async {
                  rec++;
                },
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return TextButton(
                onPressed: () async {
                  await ref
                      .read(ledgerAwareAppRefreshProvider)
                      .runPullToRefresh(ref);
                },
                child: const Text('run'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(mat, 1);
      expect(rec, 0);
    });

    testWidgets('dirty profile runs reconcile', (tester) async {
      var mat = 0;
      var rec = 0;
      final repo = FakeFirestoreDataRepository(
        userProfileForFetchSync: UserProfile(
          uid: 'test-uid',
          timezone: 'Etc/UTC',
          aggregateLastCompletedAt: DateTime.utc(2026, 4, 17),
          ledgerSourcesLastChangedAt: DateTime.utc(2026, 4, 18),
        ),
      );

      await tester.pumpWidget(
        materializedProviderScope(
          overrides: [
            authUidProvider.overrideWith((ref) => 'test-uid'),
            firestoreDataRepositoryProvider.overrideWithValue(repo),
            nowProvider.overrideWith((ref) => DateTime.utc(2026, 4, 18, 12)),
            userProfileStreamProvider.overrideWith(
              (ref) => Stream.value(
                const UserProfile(uid: 'test-uid', timezone: 'Etc/UTC'),
              ),
            ),
            materializeUpcomingServiceProvider.overrideWithValue(
              MaterializeUpcomingService(
                callable: (_) async {
                  mat++;
                },
                now: () => DateTime.utc(2026, 4, 18),
              ),
            ),
            deferredLedgerReconcileServiceProvider.overrideWithValue(
              DeferredLedgerReconcileService(
                callable: (_) async {
                  rec++;
                },
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              return TextButton(
                onPressed: () async {
                  await ref
                      .read(ledgerAwareAppRefreshProvider)
                      .runPullToRefresh(ref);
                },
                child: const Text('run'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(mat, 1);
      expect(rec, 1);
    });
  });
}
