import 'package:finko/core/data/models/finko_enums.dart';
import 'package:finko/core/data/models/ledger_transaction.dart';
import 'package:finko/core/data/models/monthly_totals.dart';
import 'package:finko/core/data/providers/finko_stream_providers.dart';
import 'package:finko/features/spending/presentation/spending_screen.dart';
import 'package:finko/l10n/app_localizations.dart';
import 'package:finko/widgets/metrics/finko_mini_income_expense_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

LedgerTransaction _tx({
  required String id,
  required String date,
  required int amountMinor,
  String categoryId = 'cat-house',
}) {
  final now = DateTime.utc(2026, 4, 1);
  return LedgerTransaction(
    id: id,
    transactionDate: date,
    loadedAt: now,
    amountMinor: amountMinor,
    direction: MoneyDirection.out_,
    currency: 'MXN',
    accountId: 'acct-1',
    categoryId: categoryId,
    type: LedgerTransactionKind.standard,
    memo: 'test1234',
    amountMinorMain: amountMinor,
    createdAt: now,
    updatedAt: now,
  );
}

MonthlyTotals _month(String ym, {int income = 0, int expense = 0}) {
  return MonthlyTotals(
    yearMonth: ym,
    incomeMinorMain: income,
    expenseMinorMain: expense,
    byCategoryMinorMain: expense > 0 ? {'cat-house': -expense} : const {},
    days: const {},
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_MX');
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
  });

  testWidgets('Spending year strip renders mini cards without exceptions', (
    tester,
  ) async {
    final txs = [
      _tx(id: '1', date: '2026-04-01', amountMinor: 10000000),
      _tx(id: '2', date: '2026-03-15', amountMinor: 4356582),
    ];

    final monthlyOverrides = <Override>[
      todayYyyyMmDdProvider.overrideWith((ref) => '2026-04-15'),
      userProfileStreamProvider.overrideWith((ref) => Stream.value(null)),
      categoriesStreamProvider.overrideWith((ref) => Stream.value(const [])),
      transactionsForDateRangeStreamProvider.overrideWith(
        (ref, range) => Stream.value(txs),
      ),
    ];

    for (var m = 1; m <= 12; m++) {
      final ym = '2026-${m.toString().padLeft(2, '0')}';
      monthlyOverrides.add(
        monthlyTotalsForMonthStreamProvider(ym).overrideWith(
          (ref) => Stream.value(
            _month(
              ym,
              income: m == 4 ? 59467300 : 0,
              expense: m == 4 ? 10000000 : (m == 3 ? 4356582 : 0),
            ),
          ),
        ),
      );
    }

    for (var y = 2019; y <= 2025; y++) {
      for (var m = 1; m <= 12; m++) {
        final ym = '$y-${m.toString().padLeft(2, '0')}';
        monthlyOverrides.add(
          monthlyTotalsForMonthStreamProvider(
            ym,
          ).overrideWith((ref) => Stream.value(null)),
        );
      }
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: monthlyOverrides,
        child: MaterialApp(
          locale: const Locale('es', 'MX'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SpendingScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Año'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);

    expect(find.byType(FinkoMiniIncomeExpenseCard), findsWidgets);
  });
}
