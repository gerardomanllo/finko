import '../data/models/ledger_transaction.dart';
import 'spending_period_descriptor.dart';

/// Keeps only periods where at least one ledger row’s `transactionDate` falls
/// inclusively in that period’s range (any type / direction).
List<SpendingPeriodDescriptor> periodsWithTransactions(
  List<SpendingPeriodDescriptor> periods,
  List<LedgerTransaction> transactions,
) {
  if (periods.isEmpty) return const [];
  final keys = <String>{};
  for (final t in transactions) {
    final d = t.transactionDate;
    for (final p in periods) {
      if (d.compareTo(p.startYyyyMmDd) >= 0 &&
          d.compareTo(p.endYyyyMmDd) <= 0) {
        keys.add(p.key);
        break;
      }
    }
  }
  return [
    for (final p in periods)
      if (keys.contains(p.key)) p,
  ];
}
