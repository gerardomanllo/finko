import 'package:flutter/material.dart';

import '../../core/ui/finko_modal_sheet_extent.dart';
import '../../l10n/app_localizations.dart';

/// Slide-up to pick ledger transaction kind filter (matches app filter index 0–3).
class TransactionKindFilterSheet extends StatelessWidget {
  const TransactionKindFilterSheet({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// 0 = all kinds … 3 = adjustment (same ring as [TransactionsListState.filterIndex]).
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = <({int index, String label})>[
      (index: 0, label: l10n.transactionsFilterAll),
      (index: 1, label: l10n.transactionsFilterStandard),
      (index: 2, label: l10n.transactionsFilterTransfer),
      (index: 3, label: l10n.transactionsFilterAdjustment),
    ];
    final normalized = selectedIndex % 4;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = finkoModalSheetMaxHeight(
          context,
          layoutMaxHeight: constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : null,
        );
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      l10n.transactionsFilterSheetTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final o = options[i];
                        return ListTile(
                          title: Text(o.label),
                          trailing: normalized == o.index
                              ? Icon(
                                  Icons.check,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () => onSelected(o.index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
