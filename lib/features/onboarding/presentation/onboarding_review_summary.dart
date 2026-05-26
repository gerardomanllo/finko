import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting/money_format.dart';
import '../../../core/theme/finko_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/onboarding_timezones.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_account_editor.dart';
import 'onboarding_category_icons.dart';
import 'onboarding_ui.dart';

String _timezoneChipLabel(AppLocalizations l10n, String labelKey) {
  return switch (labelKey) {
    'onboardingTimezoneMexicoSoutheast' =>
      l10n.onboardingTimezoneMexicoSoutheast,
    'onboardingTimezoneMexicoCentral' => l10n.onboardingTimezoneMexicoCentral,
    'onboardingTimezoneMexicoPacific' => l10n.onboardingTimezoneMexicoPacific,
    'onboardingTimezoneMexicoNorthwest' =>
      l10n.onboardingTimezoneMexicoNorthwest,
    'onboardingTimezoneUsPacific' => l10n.onboardingTimezoneUsPacific,
    'onboardingTimezoneUsMountain' => l10n.onboardingTimezoneUsMountain,
    'onboardingTimezoneUsEastern' => l10n.onboardingTimezoneUsEastern,
    _ => labelKey,
  };
}

String _resolvedTimezoneLabel(AppLocalizations l10n, String iana) {
  for (final o in kOnboardingTimezoneOptions) {
    if (o.ianaId == iana) {
      return _timezoneChipLabel(l10n, o.labelKey);
    }
  }
  return iana;
}

String _themeChipLabel(AppLocalizations l10n, String preference) {
  return switch (preference) {
    'light' => l10n.themeLight,
    'dark' => l10n.themeDark,
    'system' => l10n.themeAutomatic,
    _ => l10n.themeSystem,
  };
}

String _localeChipLabel(AppLocalizations l10n, String locale) {
  final t = locale.trim().toLowerCase();
  if (t.startsWith('en')) return l10n.onboardingLocaleEnglishUs;
  return l10n.onboardingLocaleSpanishMx;
}

String _humanDayOfMonth(int day, String localeTag) {
  final es = localeTag.toLowerCase().startsWith('es');
  if (es) {
    return switch (day) {
      1 => 'primero',
      2 => 'dos',
      3 => 'tres',
      _ => '$day',
    };
  }
  if (day >= 11 && day <= 13) return '${day}th';
  return switch (day % 10) {
    1 => '${day}st',
    2 => '${day}nd',
    3 => '${day}rd',
    _ => '${day}th',
  };
}

String _humanWeekday(int weekday, String localeTag) {
  final d = DateTime(2024, 1, 1 + (weekday - 1));
  return DateFormat.EEEE(localeTag).format(d);
}

/// Final review step: name, preference chips, and a compact summary of onboarding choices.
Widget buildOnboardingReviewSummary(
  BuildContext context,
  OnboardingDraft draft,
  AppLocalizations l10n,
  String localeTag,
) {
  final theme = Theme.of(context);
  final m = draft.profileMainCurrencyForCommit;
  final name = draft.displayName.trim().isEmpty
      ? '—'
      : draft.displayName.trim();
  final savings = draft.projectedSavingsMinor;
  final savingsColor = savings > 0
      ? FinkoColors.income
      : savings < 0
      ? theme.colorScheme.error
      : theme.colorScheme.onSurfaceVariant;

  final messagingParts = <String>[];
  if (draft.messaging.whatsAppVerified) {
    messagingParts.add(l10n.onboardingReviewMessagingWhatsAppOk);
  }
  if (draft.messaging.telegramVerified) {
    messagingParts.add(l10n.onboardingReviewMessagingTelegramOk);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FinkoColors.primaryLight, FinkoColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: FinkoColors.primary.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.onboardingReviewIntro,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      OnboardingSectionCard(
        icon: Icons.tune_rounded,
        accent: OnboardingAccents.accounts,
        title: l10n.onboardingReviewPreferences,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ReviewChip(
              icon: Icons.schedule_outlined,
              label: _resolvedTimezoneLabel(l10n, draft.timezone),
            ),
            _ReviewChip(
              icon: Icons.brightness_6_outlined,
              label: _themeChipLabel(l10n, draft.themePreference),
            ),
            _ReviewChip(
              icon: Icons.language_outlined,
              label: _localeChipLabel(l10n, draft.locale),
            ),
            _ReviewChip(
              icon: Icons.payments_outlined,
              label: draft.profileMainCurrencyForCommit,
            ),
          ],
        ),
      ),
      OnboardingSectionCard(
        icon: Icons.account_balance_wallet_outlined,
        accent: OnboardingAccents.accounts,
        title: l10n.onboardingReviewSectionAccounts,
        child: draft.accounts.isEmpty
            ? Text('—', style: theme.textTheme.bodyMedium)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in draft.accounts)
                    _ReviewListRow(
                      leading: OnboardingIconChip(
                        icon: Icons.account_balance_outlined,
                        color: Color(a.colorArgb),
                        size: 32,
                      ),
                      title: a.id == OnboardingDraft.kSystemCashAccountId
                          ? l10n.onboardingAccountNameCash
                          : a.name,
                      subtitle:
                          '${a.currency} · ${accountTypeLabel(l10n, a.type)}',
                    ),
                ],
              ),
      ),
      OnboardingSectionCard(
        icon: Icons.label_outline_rounded,
        accent: OnboardingAccents.categories,
        title: l10n.onboardingReviewSectionCategories,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in onboardingCategoriesForDisplay(draft.categories))
              _ReviewCategoryRow(c: c, l10n: l10n),
          ],
        ),
      ),
      OnboardingSectionCard(
        icon: Icons.event_repeat_rounded,
        accent: OnboardingAccents.income,
        title: l10n.onboardingReviewSectionRecurring,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in _recurringLines(draft, l10n, localeTag, m))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.paid_outlined,
                      size: 18,
                      color: OnboardingAccents.income,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(line, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      OnboardingSectionCard(
        icon: Icons.savings_outlined,
        accent: OnboardingAccents.budgets,
        title: l10n.onboardingReviewSectionBudgets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in onboardingCategoriesForDisplay(draft.categories))
              _ReviewListRow(
                leading: _ReviewCategoryRow.iconFor(c),
                title: c.name,
                trailing: formatMinorUnits(
                  draft.budgetsMinorByCategory[c.id] ?? 0,
                  m,
                  localeTag,
                ),
                kindBadge: _ReviewCategoryRow.kindBadgeFor(c, l10n),
              ),
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: savingsColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: savingsColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            OnboardingIconChip(
              icon: Icons.savings_outlined,
              color: savingsColor,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboardingReviewSectionProjected,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMinorUnits(savings, m, localeTag),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: savingsColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      OnboardingSectionCard(
        icon: Icons.chat_bubble_outline_rounded,
        accent: OnboardingAccents.transactions,
        title: l10n.onboardingReviewSectionMessaging,
        child: Text(
          messagingParts.isEmpty
              ? l10n.onboardingReviewMessagingNone
              : messagingParts.join(' · '),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

class _ReviewCategoryRow extends StatelessWidget {
  const _ReviewCategoryRow({required this.c, required this.l10n});

  final OnboardingCategoryDraft c;
  final AppLocalizations l10n;

  static Widget iconFor(OnboardingCategoryDraft c) {
    final isIncome = c.kind == OnboardingCategoryKind.income;
    final accent = isIncome ? FinkoColors.income : OnboardingAccents.budgets;
    final chipColor = c.colorArgb != null ? Color(c.colorArgb!) : accent;
    return OnboardingIconChip(
      icon: onboardingIconForKey(c.iconKey),
      color: chipColor,
      size: 32,
    );
  }

  static Widget kindBadgeFor(OnboardingCategoryDraft c, AppLocalizations l10n) {
    final isIncome = c.kind == OnboardingCategoryKind.income;
    return OnboardingKindBadge(
      label: isIncome
          ? l10n.onboardingCategoryKindIncomeShort
          : l10n.onboardingCategoryKindExpenseShort,
      accent: isIncome ? FinkoColors.income : OnboardingAccents.budgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = c.kind == OnboardingCategoryKind.income;
    final accent = isIncome ? FinkoColors.income : OnboardingAccents.budgets;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          iconFor(c),
          const SizedBox(width: 10),
          Expanded(child: Text(c.name, style: theme.textTheme.bodyMedium)),
          kindBadgeFor(c, l10n),
        ],
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FinkoColors.cloud,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinkoColors.grayLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _ReviewListRow extends StatelessWidget {
  const _ReviewListRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.kindBadge,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? kindBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.bodyMedium),
                    ),
                    ?kindBadge,
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<String> _recurringLines(
  OnboardingDraft draft,
  AppLocalizations l10n,
  String localeTag,
  String m,
) {
  final lines = <String>[];
  for (final c in onboardingCategoriesForDisplay(
    draft.categories,
  ).where((x) => x.kind == OnboardingCategoryKind.income)) {
    lines.add(_humanRecurringLine(draft, c, l10n, localeTag, m));
  }
  return lines.isEmpty ? ['—'] : lines;
}

String _humanRecurringLine(
  OnboardingDraft draft,
  OnboardingCategoryDraft category,
  AppLocalizations l10n,
  String localeTag,
  String m,
) {
  final r =
      draft.recurringByCategory[category.id] ??
      OnboardingRecurringIncomeDraft(
        categoryId: category.id,
        isRecurring: false,
      );

  if (!r.isRecurring) {
    return l10n.onboardingReviewRecurringVariable(category.name);
  }

  final amt = formatMinorUnits(r.amountMinor, m, localeTag);

  if (r.cadence == OnboardingCadence.weekly) {
    final wd = r.weekday ?? DateTime.friday;
    return l10n.onboardingReviewRecurringWeekly(
      category.name,
      amt,
      _humanWeekday(wd, localeTag),
    );
  }

  if (r.cadence == OnboardingCadence.biweekly && r.daysOfMonth.length >= 2) {
    return l10n.onboardingReviewRecurringBiweekly(
      category.name,
      amt,
      _humanDayOfMonth(r.daysOfMonth[0], localeTag),
      _humanDayOfMonth(r.daysOfMonth[1], localeTag),
    );
  }

  final day = r.daysOfMonth.isNotEmpty ? r.daysOfMonth.first : 1;
  return l10n.onboardingReviewRecurringMonthly(
    category.name,
    amt,
    _humanDayOfMonth(day, localeTag),
  );
}
