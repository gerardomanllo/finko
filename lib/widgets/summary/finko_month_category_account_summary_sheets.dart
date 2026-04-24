import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/firebase_auth_providers.dart';
import '../../core/data/models/models.dart';
import '../../core/data/providers/finko_stream_providers.dart';
import '../../core/data/repositories/firestore_data_repository.dart';
import '../../core/datetime/calendar_month_range.dart';
import '../../core/formatting/ledger_transaction_amount.dart';
import '../../core/ui/finko_modal_sheet_extent.dart';
import '../../core/spending/fixed_variable_expense.dart';
import '../../features/accounts/application/account_editor_bridge.dart';
import '../../features/onboarding/domain/onboarding_models.dart';
import '../../features/onboarding/presentation/onboarding_account_editor.dart';
import '../../features/onboarding/presentation/onboarding_account_icons.dart';
import '../../features/onboarding/presentation/onboarding_category_editor.dart';
import '../../features/onboarding/presentation/onboarding_category_icons.dart';
import '../../l10n/app_localizations.dart';
import '../transactions/finko_transaction_row_compact.dart';

Future<bool> _confirmAndDeleteCategory({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required String categoryId,
  required String categoryName,
  required String yearMonth,
  required ({String start, String end}) range,
}) async {
  final uid = ref.read(authUidProvider);
  if (uid == null) return false;
  final repo = ref.read(firestoreDataRepositoryProvider);
  final preview = await repo.previewCategoryDelete(uid, categoryId);
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.categoryDeleteCascadeTitle(categoryName)),
      content: Text(
        l10n.categoryDeleteCascadeBody(
          preview.transactions,
          preview.recurring,
          preview.upcoming,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.transactionEditorCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          child: Text(l10n.deleteCascadeConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  if (!context.mounted) return false;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await repo.deleteCategoryCascade(uid, categoryId);
    ref.invalidate(categoriesStreamProvider);
    ref.invalidate(currentMonthTotalsStreamProvider);
    ref.invalidate(monthlyTotalsForMonthStreamProvider(yearMonth));
    ref.invalidate(transactionsForDateRangeStreamProvider(range));
    ref.invalidate(userProfileStreamProvider);
    ref.invalidate(recurringRulesStreamProvider);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.deleteCascadeSuccess)));
    // Pop editor (top route), then this summary sheet — back to list.
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) Navigator.of(context).pop();
    return true;
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text('$e')));
    return false;
  }
}

Future<bool> _confirmAndDeleteAccount({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required String accountId,
  required String accountName,
  required String yearMonth,
  required ({String start, String end}) range,
}) async {
  final uid = ref.read(authUidProvider);
  if (uid == null) return false;
  final repo = ref.read(firestoreDataRepositoryProvider);
  final preview = await repo.previewAccountDelete(uid, accountId);
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.accountDeleteCascadeTitle(accountName)),
      content: Text(
        l10n.accountDeleteCascadeBody(
          preview.transactions,
          preview.recurring,
          preview.upcoming,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.transactionEditorCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          child: Text(l10n.deleteCascadeConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  if (!context.mounted) return false;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await repo.deleteAccountCascade(uid, accountId);
    ref.invalidate(accountsStreamProvider);
    ref.invalidate(categoriesStreamProvider);
    ref.invalidate(currentMonthTotalsStreamProvider);
    ref.invalidate(monthlyTotalsForMonthStreamProvider(yearMonth));
    ref.invalidate(transactionsForDateRangeStreamProvider(range));
    ref.invalidate(userProfileStreamProvider);
    ref.invalidate(recentTransactionsStreamProvider);
    ref.invalidate(recurringRulesStreamProvider);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.deleteCascadeSuccess)));
    // Pop editor (top route), then this summary sheet — back to list.
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) Navigator.of(context).pop();
    return true;
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text('$e')));
    return false;
  }
}

String _transactionTitle(LedgerTransaction t) {
  final m = t.memo?.trim();
  if (m != null && m.isNotEmpty) return m;
  return t.type == LedgerTransactionKind.transferLeg
      ? 'Transfer'
      : 'Transaction';
}

List<LedgerTransaction> _recentForCategory(
  List<LedgerTransaction> list,
  String categoryId,
) {
  final filtered = list
      .where((t) => t.categoryId == categoryId)
      .toList(growable: false);
  filtered.sort((a, b) {
    final c = b.transactionDate.compareTo(a.transactionDate);
    if (c != 0) return c;
    return b.id.compareTo(a.id);
  });
  return filtered.take(12).toList(growable: false);
}

List<LedgerTransaction> _recentForAccount(
  List<LedgerTransaction> list,
  String accountId,
) {
  final filtered = list
      .where((t) => t.accountId == accountId)
      .toList(growable: false);
  filtered.sort((a, b) {
    final c = b.transactionDate.compareTo(a.transactionDate);
    if (c != 0) return c;
    return b.id.compareTo(a.id);
  });
  return filtered.take(12).toList(growable: false);
}

OnboardingCategoryDraft _categoryDraftFromFinko(FinkoCategory c) {
  return OnboardingCategoryDraft(
    id: c.id,
    name: c.name,
    kind: c.kind == CategoryKind.income
        ? OnboardingCategoryKind.income
        : OnboardingCategoryKind.expense,
    iconKey: c.iconKey,
    isSystem: c.id == kFixedExpensesCategoryId,
  );
}

FinkoCategory _finkoCategoryFromDraft(
  FinkoCategory previous,
  OnboardingCategoryDraft d,
) {
  return FinkoCategory(
    id: previous.id,
    name: d.name,
    kind: d.kind == OnboardingCategoryKind.income
        ? CategoryKind.income
        : CategoryKind.expense,
    currency: previous.currency,
    iconKey: d.iconKey,
    colorArgb: previous.colorArgb,
    sortOrder: previous.sortOrder,
  );
}

OnboardingAccountDraft _accountDraftFromFinko(FinkoAccount a) {
  return OnboardingAccountDraft(
    id: a.id,
    name: a.name,
    type: onboardingAccountTypeFromFinko(a.type),
    currency: a.currency,
    colorArgb: a.colorArgb ?? kOnboardingAccountColorPalette.first,
    startingBalanceMinor: 0,
    iconKey: a.iconKey,
    isSystem: a.isSystem,
    creditLimitMinor: a.creditLimitMinor,
  );
}

FinkoAccount _finkoAccountFromDraft(
  FinkoAccount previous,
  OnboardingAccountDraft d,
) {
  return FinkoAccount(
    id: previous.id,
    name: d.name,
    type: previous.type,
    currency: previous.currency,
    balanceMinor: previous.balanceMinor,
    balanceMinorMain: previous.balanceMinorMain,
    includeInNetCash: previous.includeInNetCash,
    sortOrder: previous.sortOrder,
    createdAt: previous.createdAt,
    updatedAt: previous.updatedAt,
    iconKey: d.iconKey,
    colorArgb: d.colorArgb,
    creditLimitMinor: d.creditLimitMinor ?? previous.creditLimitMinor,
    isSystem: previous.isSystem,
  );
}

/// Category drill-down: month total, recent ledger rows, edit (onboarding-style sheet).
Future<void> showFinkoCategoryMonthSummarySheet({
  required BuildContext context,
  required WidgetRef ref,
  required FinkoCategory category,
  required String yearMonth,
  required String mainCurrency,
}) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final bounds = calendarMonthStartEndYyyyMmDd(yearMonth);
  final range = (start: bounds.startYyyyMmDd, end: bounds.endYyyyMmDd);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxH = finkoModalSheetMaxHeight(
            context,
            layoutMaxHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Consumer(
              builder: (context, sheetRef, _) {
                final monthAsync = sheetRef.watch(
                  monthlyTotalsForMonthStreamProvider(yearMonth),
                );
                final txAsync = sheetRef.watch(
                  transactionsForDateRangeStreamProvider(range),
                );
                final monthMinor =
                    monthAsync.valueOrNull?.byCategoryMinorMain[category.id] ??
                    0;
                final txs = txAsync.maybeWhen(
                  data: (list) => _recentForCategory(list, category.id),
                  orElse: () => const <LedgerTransaction>[],
                );

                return SizedBox(
                  height: maxH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Icon(onboardingIconForKey(category.iconKey)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  l10n.summaryYearMonthHeading(yearMonth),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.summaryMonthTotalLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signedMoneyLabel(monthMinor, mainCurrency, locale),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.summaryRecentTransactionsLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: txAsync.when(
                          data: (_) {
                            if (txs.isEmpty) {
                              return Center(
                                child: Text(
                                  l10n.summaryNoTransactionsThisMonth,
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: txs.length,
                              separatorBuilder: (context, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final t = txs[i];
                                final lines = transactionAmountPrimarySecondary(
                                  t: t,
                                  mainCurrency: mainCurrency,
                                  locale: locale,
                                );
                                return FinkoTransactionRowCompact(
                                  title: _transactionTitle(t),
                                  subtitle: t.transactionDate,
                                  amountText: lines.primary,
                                  secondaryAmountText: lines.secondary,
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('$e')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          showOnboardingCategoryEditor(
                            context: context,
                            l10n: l10n,
                            existing: _categoryDraftFromFinko(category),
                            lockKind: category.id == kFixedExpensesCategoryId,
                            onDelete: category.id == kFixedExpensesCategoryId
                                ? null
                                : () => _confirmAndDeleteCategory(
                                    context: context,
                                    ref: sheetRef,
                                    l10n: l10n,
                                    categoryId: category.id,
                                    categoryName: category.name,
                                    yearMonth: yearMonth,
                                    range: range,
                                  ),
                            onSave: (draft) {
                              final uid = sheetRef.read(authUidProvider);
                              if (uid == null) return;
                              final next = _finkoCategoryFromDraft(
                                category,
                                draft,
                              );
                              sheetRef
                                  .read(firestoreDataRepositoryProvider)
                                  .updateCategory(uid, next)
                                  .then((_) {
                                    sheetRef.invalidate(
                                      categoriesStreamProvider,
                                    );
                                    sheetRef.invalidate(
                                      currentMonthTotalsStreamProvider,
                                    );
                                    sheetRef.invalidate(
                                      monthlyTotalsForMonthStreamProvider(
                                        yearMonth,
                                      ),
                                    );
                                    sheetRef.invalidate(
                                      transactionsForDateRangeStreamProvider(
                                        range,
                                      ),
                                    );
                                  })
                                  .catchError((Object e) {
                                    messenger?.showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  });
                            },
                          );
                        },
                        child: Text(l10n.onboardingEditCategory),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}

/// Account drill-down: month net in main currency, recent rows, edit (sheet).
Future<void> showFinkoAccountMonthSummarySheet({
  required BuildContext context,
  required WidgetRef ref,
  required FinkoAccount account,
  required String yearMonth,
  required String mainCurrency,
}) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final bounds = calendarMonthStartEndYyyyMmDd(yearMonth);
  final range = (start: bounds.startYyyyMmDd, end: bounds.endYyyyMmDd);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxH = finkoModalSheetMaxHeight(
            context,
            layoutMaxHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Consumer(
              builder: (context, sheetRef, _) {
                final txAsync = sheetRef.watch(
                  transactionsForDateRangeStreamProvider(range),
                );
                final netMinor = txAsync.maybeWhen(
                  data: (list) => sumSignedMinorMainComparableForAccount(
                    list,
                    account.id,
                    mainCurrency,
                  ),
                  orElse: () => 0,
                );
                final txs = txAsync.maybeWhen(
                  data: (list) => _recentForAccount(list, account.id),
                  orElse: () => const <LedgerTransaction>[],
                );

                return SizedBox(
                  height: maxH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: account.colorArgb != null
                                ? Color(account.colorArgb!)
                                : null,
                            child: Icon(
                              onboardingAccountIconForKey(account.iconKey),
                              color: account.colorArgb != null
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  l10n.summaryYearMonthHeading(yearMonth),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.summaryMonthTotalLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signedMoneyLabel(netMinor, mainCurrency, locale),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.summaryRecentTransactionsLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: txAsync.when(
                          data: (_) {
                            if (txs.isEmpty) {
                              return Center(
                                child: Text(
                                  l10n.summaryNoTransactionsThisMonth,
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: txs.length,
                              separatorBuilder: (context, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final t = txs[i];
                                final lines = transactionAmountPrimarySecondary(
                                  t: t,
                                  mainCurrency: mainCurrency,
                                  locale: locale,
                                );
                                return FinkoTransactionRowCompact(
                                  title: _transactionTitle(t),
                                  subtitle: t.transactionDate,
                                  amountText: lines.primary,
                                  secondaryAmountText: lines.secondary,
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('$e')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          showOnboardingAccountEditor(
                            context: context,
                            l10n: l10n,
                            existing: _accountDraftFromFinko(account),
                            metadataOnly: true,
                            onDelete: () => _confirmAndDeleteAccount(
                              context: context,
                              ref: sheetRef,
                              l10n: l10n,
                              accountId: account.id,
                              accountName: account.name,
                              yearMonth: yearMonth,
                              range: range,
                            ),
                            onSave: (draft) {
                              final uid = sheetRef.read(authUidProvider);
                              if (uid == null) return;
                              final next = _finkoAccountFromDraft(
                                account,
                                draft,
                              );
                              sheetRef
                                  .read(firestoreDataRepositoryProvider)
                                  .updateAccountMetadata(uid, next)
                                  .then((_) {
                                    sheetRef.invalidate(accountsStreamProvider);
                                    sheetRef.invalidate(
                                      transactionsForDateRangeStreamProvider(
                                        range,
                                      ),
                                    );
                                  })
                                  .catchError((Object e) {
                                    messenger?.showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  });
                            },
                          );
                        },
                        child: Text(l10n.onboardingEditAccount),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}
