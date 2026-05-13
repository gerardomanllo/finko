import 'package:finko/core/auth/firebase_auth_providers.dart';
import 'package:finko/core/data/repositories/firestore_data_repository.dart';
import 'package:finko/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finko/l10n/app_localizations.dart';
import 'package:finko/widgets/metrics/finko_two_metric_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_firestore_data_repository.dart';

void main() {
  testWidgets('Dashboard shows metric carousel when streams resolve', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUidProvider.overrideWith((ref) => null),
          firestoreDataRepositoryProvider.overrideWithValue(
            FakeFirestoreDataRepository(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FinkoTwoMetricCarousel), findsOneWidget);
  });
}
