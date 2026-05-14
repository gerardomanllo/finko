import '../data/models/ledger_transaction.dart';
import '../data/models/upcoming_transaction.dart';

/// Resolves a merged [UpcomingTransaction] (dashboard / Recurring tab) to a
/// concrete [LedgerTransaction] when the row is backed by `transactions/`.
LedgerTransaction? ledgerTransactionForMergedUpcoming(
  UpcomingTransaction u,
  Iterable<LedgerTransaction> ledgerFuture,
) {
  const ledgerPrefix = 'ledger_preview_';
  if (u.id.startsWith(ledgerPrefix)) {
    final txId = u.id.substring(ledgerPrefix.length);
    for (final t in ledgerFuture) {
      if (t.id == txId) return t;
    }
    return null;
  }
  for (final t in ledgerFuture) {
    final sid = t.sourceUpcomingId;
    if (sid != null && sid.isNotEmpty && sid == u.id) return t;
  }
  return null;
}
