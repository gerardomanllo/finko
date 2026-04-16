import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finko/core/data/finko_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestorePaths', () {
    test('user-scoped paths', () {
      expect(FirestorePaths.userDoc('u1'), 'users/u1');
      expect(
        FirestorePaths.transactionDoc('u1', 'tx1'),
        'users/u1/transactions/tx1',
      );
      expect(
        FirestorePaths.monthlyTotalsDoc('u1', '2026-04'),
        'users/u1/monthlyTotals/2026-04',
      );
      expect(
        FirestorePaths.forexRatesDoc('2026-04-15'),
        'forexRates/2026-04-15',
      );
    });
  });

  group('LedgerTransaction', () {
    test('round-trip map', () {
      final t0 = DateTime.utc(2026, 4, 15, 12);
      final tx = LedgerTransaction(
        id: 'tx1',
        transactionDate: '2026-04-15',
        loadedAt: t0,
        amountMinor: 100,
        direction: MoneyDirection.out_,
        currency: 'MXN',
        accountId: 'a1',
        categoryId: 'c1',
        type: LedgerTransactionKind.standard,
        memo: 'Coffee',
        createdAt: t0,
        updatedAt: t0,
      );
      final map = tx.toFirestore();
      expect(map['direction'], 'out');
      expect(map['type'], 'standard');
      final back = LedgerTransaction.fromFirestore('tx1', map);
      expect(back.amountMinor, 100);
      expect(back.direction, MoneyDirection.out_);
    });
  });

  group('MonthlyTotals', () {
    test('parses nested budgets and days', () {
      final data = {
        'yearMonth': '2026-04',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 4, 1)),
        'incomeMinorMain': 5000,
        'expenseMinorMain': 3000,
        'byCategoryMinorMain': {'cat1': 200},
        'budgets': {
          'cat1': {'targetMinorMain': 400, 'kind': 'expense'},
        },
        'days': {
          '15': {
            'incomeMinorMain': 100,
            'expenseMinorMain': 50,
            'netWorthEodMinorMain': 10000,
          },
        },
      };
      final m = MonthlyTotals.fromFirestore(data);
      expect(m.incomeMinorMain, 5000);
      expect(m.budgets['cat1']?.targetMinorMain, 400);
      expect(m.days['15']?.netWorthEodMinorMain, 10000);
      final out = m.toFirestore();
      expect(out['yearMonth'], '2026-04');
    });

    test('parses legacy flat numeric budgets (onboarding shorthand)', () {
      final data = {
        'yearMonth': '2026-04',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 4, 1)),
        'incomeMinorMain': 0,
        'expenseMinorMain': 1000,
        'byCategoryMinorMain': <String, int>{},
        'budgets': {
          'cat1': 50_000,
        },
        'days': <String, dynamic>{},
      };
      final m = MonthlyTotals.fromFirestore(data);
      expect(m.budgets['cat1']?.targetMinorMain, 50_000);
      expect(m.budgets['cat1']?.kind, BudgetKind.expense);
    });
  });

  group('RecurringRule', () {
    test('round-trip and legacy isIncome', () {
      final t = DateTime.utc(2026, 4, 1);
      final rule = RecurringRule(
        id: 'r1',
        name: 'Salary',
        kind: UpcomingKind.standard,
        amountMinor: 50_000,
        direction: MoneyDirection.in_,
        currency: 'MXN',
        categoryId: 'cat1',
        accountId: 'acc1',
        cadence: RecurringCadence.twiceMonthly,
        daysOfMonth: const [1, 15],
        active: true,
        nextTransactionDate: '2026-05-01',
        createdAt: t,
        updatedAt: t,
      );
      final map = rule.toFirestore();
      final back = RecurringRule.fromFirestore('r1', map);
      expect(back.cadence, RecurringCadence.twiceMonthly);
      expect(back.daysOfMonth, [1, 15]);

      final legacy = RecurringRule.fromFirestore('r2', {
        'name': 'Legacy',
        'kind': 'standard',
        'amountMinor': 100,
        'isIncome': true,
        'currency': 'MXN',
        'cadence': 'monthly',
        'active': true,
        'nextTransactionDate': '2026-05-01',
        'createdAt': Timestamp.fromDate(t),
        'updatedAt': Timestamp.fromDate(t),
      });
      expect(legacy.direction, MoneyDirection.in_);
    });
  });

  group('UserProfile', () {
    test('parses integrations', () {
      final data = {
        'displayName': 'Ada',
        'mainCurrency': 'MXN',
        'locale': 'es-MX',
        'onboardingCompleted': true,
        'integrations': {
          'whatsapp': {
            'phoneE164': '+525512345678',
            'verifiedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
          },
        },
      };
      final p = UserProfile.fromFirestore('uid1', data);
      expect(p.integrations.whatsapp?.phoneE164, '+525512345678');
      expect(p.mainCurrency, 'MXN');
    });
  });
}
