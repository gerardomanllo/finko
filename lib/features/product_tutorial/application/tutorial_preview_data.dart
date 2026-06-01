import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models/finko_category.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/models/ledger_transaction.dart';
import '../../../core/data/models/monthly_totals.dart';
import '../../../core/data/models/upcoming_transaction.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import 'tutorial_preview_l10n.dart';

List<LedgerTransaction> buildTutorialPreviewLedgerTransactions(Ref ref) {
  final today = ref.read(todayYyyyMmDdProvider);
  final accounts = ref.read(accountsStreamProvider).valueOrNull ?? [];
  final categories =
      ref.read(categoriesStreamProvider).valueOrNull ?? <FinkoCategory>[];
  final main =
      ref.read(userProfileStreamProvider).valueOrNull?.mainCurrency ??
      accounts.firstOrNull?.currency ??
      'MXN';
  final accountId = accounts.firstOrNull?.id ?? 'tour-account';
  final expenseCat = categories
      .where((c) => c.kind == CategoryKind.expense)
      .firstOrNull;
  final incomeCat = categories
      .where((c) => c.kind == CategoryKind.income)
      .firstOrNull;
  final expenseId = expenseCat?.id ?? 'tour-expense';
  final incomeId = incomeCat?.id ?? 'tour-income';
  final now = DateTime.now().toUtc();

  final memoGroceries = tutorialPreviewString(
    ref,
    (l) => l.tutorialPreviewTxnGroceries,
  );
  final memoPaycheck = tutorialPreviewString(
    ref,
    (l) => l.tutorialPreviewTxnPaycheck,
  );
  final memoUtilities = tutorialPreviewString(
    ref,
    (l) => l.tutorialPreviewTxnUtilities,
  );

  String dayOffset(int days) {
    final p = today.split('-');
    final d = DateTime(
      int.parse(p[0]),
      int.parse(p[1]),
      int.parse(p[2]),
    ).subtract(Duration(days: days));
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  LedgerTransaction row({
    required String id,
    required String date,
    required MoneyDirection direction,
    required String categoryId,
    required int amount,
    required String memo,
  }) {
    return LedgerTransaction(
      id: id,
      transactionDate: date,
      loadedAt: now,
      amountMinor: amount,
      direction: direction,
      currency: main,
      accountId: accountId,
      categoryId: categoryId,
      type: LedgerTransactionKind.standard,
      memo: memo,
      amountMinorMain: amount,
      createdAt: now,
      updatedAt: now,
    );
  }

  return [
    row(
      id: 'tour-tx-1',
      date: dayOffset(1),
      direction: MoneyDirection.out_,
      categoryId: expenseId,
      amount: 45000,
      memo: memoGroceries,
    ),
    row(
      id: 'tour-tx-2',
      date: dayOffset(3),
      direction: MoneyDirection.in_,
      categoryId: incomeId,
      amount: 120000,
      memo: memoPaycheck,
    ),
    row(
      id: 'tour-tx-3',
      date: dayOffset(5),
      direction: MoneyDirection.out_,
      categoryId: expenseId,
      amount: 28000,
      memo: memoUtilities,
    ),
  ];
}

MonthlyTotals? buildTutorialPreviewMonthlyTotals(Ref ref, String yearMonth) {
  final categories =
      ref.read(categoriesStreamProvider).valueOrNull ?? <FinkoCategory>[];
  final byCat = <String, int>{};
  for (final c in categories.where((c) => c.kind == CategoryKind.expense)) {
    byCat[c.id] = -15000;
  }
  if (byCat.isEmpty) {
    byCat['tour-expense'] = -45000;
  }
  return MonthlyTotals(
    yearMonth: yearMonth,
    incomeMinorMain: 120000,
    expenseMinorMain: 75000,
    byCategoryMinorMain: byCat,
    days: const {},
  );
}

List<UpcomingTransaction> buildTutorialPreviewUpcoming(Ref ref) {
  final today = ref.read(todayYyyyMmDdProvider);
  final accounts = ref.read(accountsStreamProvider).valueOrNull ?? [];
  final categories =
      ref.read(categoriesStreamProvider).valueOrNull ?? <FinkoCategory>[];
  final main =
      ref.read(userProfileStreamProvider).valueOrNull?.mainCurrency ??
      accounts.firstOrNull?.currency ??
      'MXN';
  final accountId = accounts.firstOrNull?.id;
  final expenseCat = categories
      .where((c) => c.kind == CategoryKind.expense)
      .firstOrNull;
  final incomeCat = categories
      .where((c) => c.kind == CategoryKind.income)
      .firstOrNull;
  final now = DateTime.now().toUtc();

  final memoSalary = tutorialPreviewString(
    ref,
    (l) => l.tutorialPreviewUpcomingSalary,
  );
  final memoRent = tutorialPreviewString(
    ref,
    (l) => l.tutorialPreviewUpcomingRent,
  );

  String dayOffset(int days) {
    final p = today.split('-');
    final d = DateTime(
      int.parse(p[0]),
      int.parse(p[1]),
      int.parse(p[2]),
    ).add(Duration(days: days));
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  UpcomingTransaction u({
    required String id,
    required String date,
    required MoneyDirection direction,
    String? categoryId,
    int amount = 50000,
    required String memo,
  }) {
    return UpcomingTransaction(
      id: id,
      transactionDate: date,
      kind: UpcomingKind.standard,
      amountMinor: amount,
      direction: direction,
      currency: main,
      accountId: accountId,
      categoryId: categoryId,
      memo: memo,
      loadedAt: now,
      updatedAt: now,
    );
  }

  return [
    u(
      id: 'tour-up-1',
      date: dayOffset(2),
      direction: MoneyDirection.out_,
      categoryId: expenseCat?.id,
      memo: memoRent,
    ),
    u(
      id: 'tour-up-2',
      date: dayOffset(5),
      direction: MoneyDirection.in_,
      categoryId: incomeCat?.id,
      amount: 80000,
      memo: memoSalary,
    ),
    u(
      id: 'tour-up-3',
      date: dayOffset(9),
      direction: MoneyDirection.out_,
      categoryId: expenseCat?.id,
      memo: memoRent,
    ),
  ];
}
