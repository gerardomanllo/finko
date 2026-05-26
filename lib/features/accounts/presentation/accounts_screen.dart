import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/models/finko_account.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/category_opening_balance.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/data/repositories/firestore_data_repository.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/summary/finko_month_category_account_summary_sheets.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';
import '../application/account_editor_bridge.dart';
import '../../onboarding/presentation/onboarding_account_editor.dart';
import '../../onboarding/presentation/onboarding_account_icons.dart';

const List<FinkoAccountType> _kAccountTypeSectionOrder = <FinkoAccountType>[
  FinkoAccountType.cash,
  FinkoAccountType.checking,
  FinkoAccountType.creditCard,
  FinkoAccountType.savings,
  FinkoAccountType.investment,
  FinkoAccountType.loan,
  FinkoAccountType.mortgage,
];

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
    final yearMonth = ref.watch(currentYearMonthProvider);
    final bottomInset =
        88.0 + MediaQuery.paddingOf(context).bottom; // extended FAB + margin

    void openAddAccount() {
      final uid = ref.read(authUidProvider);
      if (uid == null) return;
      showOnboardingAccountEditor(
        context: context,
        l10n: l10n,
        existing: null,
        metadataOnly: false,
        onSave: (draft) async {
          try {
            final categories =
                ref.read(categoriesStreamProvider).valueOrNull ?? [];
            final openingCategoryId = draft.startingBalanceMinor != 0
                ? firstExpenseCategoryIdBySortOrder(categories)
                : null;
            if (draft.startingBalanceMinor != 0 && openingCategoryId == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.accountsNeedExpenseCategory)),
                );
              }
              return;
            }
            await ref
                .read(firestoreDataRepositoryProvider)
                .createAccount(
                  uid,
                  name: draft.name,
                  type: finkoAccountTypeFromOnboarding(draft.type),
                  currency: draft.currency,
                  colorArgb: draft.colorArgb,
                  iconKey: draft.iconKey,
                  startingBalanceMinor: draft.startingBalanceMinor,
                  openingBalanceTransactionDateYyyyMmDd: ref.read(
                    todayYyyyMmDdProvider,
                  ),
                  openingBalanceCategoryId: openingCategoryId,
                );
            if (context.mounted) {
              ref.invalidate(accountsStreamProvider);
              ref.invalidate(currentMonthTotalsStreamProvider);
              ref.invalidate(recentTransactionsStreamProvider);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$e')));
            }
          }
        },
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountsTitle)),
      floatingActionButton: async.maybeWhen(
        data: (_) => FloatingActionButton.extended(
          heroTag: 'accounts_add_fab',
          onPressed: openAddAccount,
          icon: const Icon(Icons.add),
          label: Text(l10n.accountsAddAccount),
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
        ),
        orElse: () => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: async.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset),
                child: Text(l10n.emptyNoAccounts),
              ),
            );
          }

          final children = <Widget>[];
          for (final t in _kAccountTypeSectionOrder) {
            final sectionAccounts =
                accounts.where((a) => a.type == t).toList(growable: false)
                  ..sort((a, b) {
                    final o = a.sortOrder.compareTo(b.sortOrder);
                    if (o != 0) return o;
                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });
            if (sectionAccounts.isEmpty) continue;

            children.add(
              _SectionTitle(
                text: accountTypeLabel(l10n, onboardingAccountTypeFromFinko(t)),
              ),
            );
            children.add(const SizedBox(height: 8));
            for (final a in sectionAccounts) {
              children.add(
                _AccountRow(
                  account: a,
                  mainCurrency: mainCurrency,
                  locale: locale,
                  onTap: () {
                    showFinkoAccountMonthSummarySheet(
                      context: context,
                      ref: ref,
                      account: a,
                      yearMonth: yearMonth,
                      mainCurrency: mainCurrency,
                    );
                  },
                ),
              );
            }
            children.add(const SizedBox(height: 16));
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(12, 16, 12, bottomInset),
            children: children,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.mainCurrency,
    required this.locale,
    required this.onTap,
  });

  final FinkoAccount account;
  final String mainCurrency;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isForeign = account.currency != mainCurrency;
    final mainAmount = formatMinorUnits(
      account.balanceMinorMain ?? account.balanceMinor,
      mainCurrency,
      locale,
    );
    final actualAmount = formatMinorUnitsWithCode(
      account.balanceMinor,
      account.currency,
      locale,
    );

    final bg = account.colorArgb;
    final leading = CircleAvatar(
      backgroundColor: bg != null ? Color(bg) : null,
      child: Icon(
        onboardingAccountIconForKey(account.iconKey),
        color: bg != null ? Colors.white : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FinkoPaperCard(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        child: ListTile(
          contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
          leading: leading,
          title: Text(account.name),
          subtitle: Text(
            accountTypeLabel(
              AppLocalizations.of(context),
              onboardingAccountTypeFromFinko(account.type),
            ),
          ),
          trailing: isForeign
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [Text('~$mainAmount'), Text(actualAmount)],
                )
              : Text(mainAmount),
          onTap: onTap,
        ),
      ),
    );
  }
}
