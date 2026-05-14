import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/ledger_transaction.dart';
import '../../core/data/models/upcoming_transaction.dart';
import '../../core/data/providers/finko_stream_providers.dart';
import '../../core/upcoming/ledger_transaction_for_merged_upcoming.dart';
import 'ledger_transaction_editor_sheet.dart';

/// Opens [LedgerTransactionEditorSheet] for a merged upcoming row: future-dated
/// ledger rows, `upcomingTransactions/`, or a recurring rule preview.
void openMergedUpcomingEditor(
  BuildContext context,
  WidgetRef ref,
  UpcomingTransaction u, {
  required List<LedgerTransaction> ledgerCandidates,
}) {
  final ledger = ledgerTransactionForMergedUpcoming(u, ledgerCandidates);
  if (ledger != null) {
    LedgerTransactionEditorSheet.show(context, transaction: ledger);
    return;
  }

  const recurringPreview = 'recurring_preview_';
  if (u.id.startsWith(recurringPreview) && u.recurringRuleId != null) {
    final rules = ref.read(recurringRulesStreamProvider).valueOrNull;
    if (rules != null) {
      for (final r in rules) {
        if (r.id == u.recurringRuleId) {
          LedgerTransactionEditorSheet.show(context, editingRecurringRule: r);
          return;
        }
      }
    }
  }

  const ledgerPreview = 'ledger_preview_';
  if (!u.id.startsWith(ledgerPreview)) {
    LedgerTransactionEditorSheet.show(context, editingUpcoming: u);
  }
}
