import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase_auth_providers.dart';
import '../../../core/data/models/finko_category.dart';
import '../../../core/data/models/finko_enums.dart';
import '../../../core/data/providers/finko_stream_providers.dart';
import '../../../core/data/repositories/firestore_data_repository.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/categories/finko_category_icon_avatar.dart';
import '../../../widgets/summary/finko_month_category_account_summary_sheets.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/onboarding_category_editor.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catsAsync = ref.watch(categoriesStreamProvider);
    final monthAsync = ref.watch(currentMonthTotalsStreamProvider);
    final yearMonth = ref.watch(currentYearMonthProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mainCurrency = profileAsync.valueOrNull?.mainCurrency ?? 'MXN';
    final byCategory = monthAsync.valueOrNull?.byCategoryMinorMain ?? {};
    final bottomInset =
        88.0 + MediaQuery.paddingOf(context).bottom; // extended FAB + margin

    void openAddCategory() {
      final uid = ref.read(authUidProvider);
      if (uid == null) return;
      showOnboardingCategoryEditor(
        context: context,
        l10n: l10n,
        existing: null,
        onSave: (draft) async {
          try {
            await ref
                .read(firestoreDataRepositoryProvider)
                .createCategory(
                  uid,
                  name: draft.name,
                  kind: draft.kind == OnboardingCategoryKind.income
                      ? CategoryKind.income
                      : CategoryKind.expense,
                  iconKey: draft.iconKey,
                  colorArgb: draft.colorArgb,
                );
            if (context.mounted) {
              ref.invalidate(categoriesStreamProvider);
              ref.invalidate(currentMonthTotalsStreamProvider);
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
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      floatingActionButton: catsAsync.maybeWhen(
        data: (_) => FloatingActionButton.extended(
          heroTag: 'categories_add_fab',
          onPressed: openAddCategory,
          icon: const Icon(Icons.add),
          label: Text(l10n.categoriesAddCategory),
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
        ),
        orElse: () => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: catsAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset),
                child: Text(l10n.categoriesEmpty),
              ),
            );
          }
          final income = categories
              .where((c) => c.kind == CategoryKind.income)
              .toList(growable: false);
          final expense = categories
              .where((c) => c.kind == CategoryKind.expense)
              .toList(growable: false);

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
            children: [
              if (income.isNotEmpty) ...[
                _SectionTitle(text: l10n.onboardingCategoryKindIncome),
                const SizedBox(height: 8),
                ...income.map(
                  (c) => _CategoryRow(
                    category: c,
                    monthMinor: byCategory[c.id] ?? 0,
                    mainCurrency: mainCurrency,
                    locale: locale,
                    onTap: () {
                      showFinkoCategoryMonthSummarySheet(
                        context: context,
                        ref: ref,
                        category: c,
                        yearMonth: yearMonth,
                        mainCurrency: mainCurrency,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (expense.isNotEmpty) ...[
                _SectionTitle(text: l10n.onboardingCategoryKindExpense),
                const SizedBox(height: 8),
                ...expense.map(
                  (c) => _CategoryRow(
                    category: c,
                    monthMinor: byCategory[c.id] ?? 0,
                    mainCurrency: mainCurrency,
                    locale: locale,
                    onTap: () {
                      showFinkoCategoryMonthSummarySheet(
                        context: context,
                        ref: ref,
                        category: c,
                        yearMonth: yearMonth,
                        mainCurrency: mainCurrency,
                      );
                    },
                  ),
                ),
              ],
            ],
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.monthMinor,
    required this.mainCurrency,
    required this.locale,
    required this.onTap,
  });

  final FinkoCategory category;
  final int monthMinor;
  final String mainCurrency;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sign = monthMinor >= 0 ? '+' : '−';
    final trailing =
        '$sign${formatMinorUnits(monthMinor.abs(), mainCurrency, locale)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FinkoPaperCard(
        child: ListTile(
          leading: FinkoCategoryIconAvatar.fromCategory(category),
          title: Text(category.name),
          trailing: Text(
            trailing,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
