import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(accountsStreamProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mainCurrency =
        profileAsync.valueOrNull?.mainCurrency ??
        async.valueOrNull?.firstOrNull?.currency ??
        'MXN';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountsTitle)),
      body: async.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(child: Text(l10n.emptyNoAccounts));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, i) {
              final a = accounts[i];
              final isForeign = a.currency != mainCurrency;
              final mainAmount = formatMinorUnits(
                a.balanceMinorMain ?? a.balanceMinor,
                mainCurrency,
                locale,
              );
              final actualAmount = formatMinorUnitsWithCode(
                a.balanceMinor,
                a.currency,
                locale,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FinkoPaperCard(
                  child: ListTile(
                    title: Text(a.name),
                    subtitle: Text(a.type.wireName),
                    trailing: isForeign
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('~$mainAmount'),
                              Text(actualAmount),
                            ],
                          )
                        : Text(mainAmount),
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
