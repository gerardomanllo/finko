import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/surfaces/finko_paper_card.dart';

/// Shown on stack screens during the tour when real lists are empty.
class TutorialPreviewListRow extends StatelessWidget {
  const TutorialPreviewListRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.leading,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FinkoPaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(trailing, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class TutorialCategoriesPreview extends StatelessWidget {
  const TutorialCategoriesPreview({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.onboardingCategoryKindExpense,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TutorialPreviewListRow(
          title: l10n.tutorialPreviewCategoryExpense,
          subtitle: l10n.tutorialPreviewBudgetSample,
          trailing: '−\$450',
          leading: Icon(
            Icons.restaurant,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class TutorialAccountsPreview extends StatelessWidget {
  const TutorialAccountsPreview({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return TutorialPreviewListRow(
      title: l10n.tutorialPreviewAccountChecking,
      subtitle: l10n.accountTypeChecking,
      trailing: '\$12,000',
      leading: Icon(
        Icons.account_balance,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
