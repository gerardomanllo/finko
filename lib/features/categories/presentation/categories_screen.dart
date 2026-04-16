import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final monthAsync = ref.watch(currentMonthTotalsStreamProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      body: monthAsync.when(
        data: (m) {
          final keys = m?.byCategoryMinorMain.keys.toList() ?? [];
          if (keys.isEmpty) {
            return Center(child: Text(l10n.categoriesEmpty));
          }
          keys.sort();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final k = keys[i];
              final v = m!.byCategoryMinorMain[k] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FinkoPaperCard(
                  child: ListTile(
                    title: Text(k),
                    trailing: Text(formatMinorUnits(v, 'MXN', locale)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
