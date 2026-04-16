import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/models/user_profile.dart';
import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/onboarding_timezones.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_account_editor.dart';

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
    _ => l10n.themeSystem,
  };
}

String _localeChipLabel(AppLocalizations l10n, String locale) {
  final t = locale.trim().toLowerCase();
  if (t.startsWith('en')) return l10n.onboardingLocaleEnglishUs;
  return l10n.onboardingLocaleSpanishMx;
}

/// Final review step: name, preference chips, and a compact summary of onboarding choices.
Widget buildOnboardingReviewSummary(
  BuildContext context,
  OnboardingDraft draft,
  AppLocalizations l10n,
  String localeTag,
) {
  final theme = Theme.of(context);
  final m = kDefaultMainCurrency;
  final name = draft.displayName.trim().isEmpty
      ? '—'
      : draft.displayName.trim();

  final incomeCats = draft.categories.where(
    (c) => c.kind == OnboardingCategoryKind.income,
  );
  final expenseCats = draft.categories.where(
    (c) => c.kind == OnboardingCategoryKind.expense,
  );

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
      Text(name, style: theme.textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(
        l10n.onboardingReviewIntro,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      Text(l10n.onboardingReviewPreferences, style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(
            label: Text(_resolvedTimezoneLabel(l10n, draft.timezone)),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text(_themeChipLabel(l10n, draft.themePreference)),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text(_localeChipLabel(l10n, draft.locale)),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text(
        l10n.onboardingReviewSectionAccounts,
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Text(
        draft.accounts.isEmpty
            ? '—'
            : draft.accounts
                  .map(
                    (a) =>
                        '${a.name} · ${a.currency} · ${accountTypeLabel(l10n, a.type)}',
                  )
                  .join('\n'),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      Text(
        l10n.onboardingReviewSectionCategories,
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Text(
        l10n.onboardingReviewCategoriesCounts(
          incomeCats.length,
          expenseCats.length,
        ),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      Text(
        l10n.onboardingReviewSectionRecurring,
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Text(
        _recurringSummary(draft, l10n, localeTag, m),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      Text(
        l10n.onboardingReviewSectionBudgets,
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Text(
        draft.categories
            .map((c) {
              final minor = draft.budgetsMinorByCategory[c.id] ?? 0;
              final label = c.id == OnboardingDraft.kFixedExpensesCategory.id
                  ? l10n.onboardingCategoryFixedExpenses
                  : c.name;
              return '$label: ${formatMinorUnits(minor, m, localeTag)}';
            })
            .join('\n'),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      Text(
        l10n.onboardingReviewSectionProjected,
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Text(
        formatMinorUnits(draft.projectedSavingsMinor, m, localeTag),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      Text(
        l10n.onboardingReviewSectionMessaging,
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Text(
        messagingParts.isEmpty
            ? l10n.onboardingReviewMessagingNone
            : messagingParts.join(' · '),
        style: theme.textTheme.bodyMedium,
      ),
    ],
  );
}

String _recurringSummary(
  OnboardingDraft draft,
  AppLocalizations l10n,
  String localeTag,
  String m,
) {
  final lines = <String>[];
  for (final c in draft.categories.where(
    (x) => x.kind == OnboardingCategoryKind.income,
  )) {
    final r =
        draft.recurringByCategory[c.id] ??
        OnboardingRecurringIncomeDraft(categoryId: c.id, isRecurring: false);
    if (!r.isRecurring) {
      lines.add('${c.name}: ${l10n.onboardingReviewRecurringOff}');
      continue;
    }
    final amt = formatMinorUnits(r.amountMinor, m, localeTag);
    final cadence = switch (r.cadence) {
      OnboardingCadence.monthly => l10n.onboardingCadenceMonthly,
      OnboardingCadence.biweekly => l10n.onboardingCadenceBiweekly,
      OnboardingCadence.weekly => l10n.onboardingCadenceWeekly,
    };
    String when;
    if (r.cadence == OnboardingCadence.weekly) {
      final wd = r.weekday;
      if (wd != null && wd >= 1 && wd <= 7) {
        final d = DateTime(2024, 1, 1 + (wd - 1));
        when = DateFormat.E(localeTag).format(d);
      } else {
        when = '—';
      }
    } else if (r.cadence == OnboardingCadence.biweekly &&
        r.daysOfMonth.length >= 2) {
      when = l10n.onboardingReviewBiweeklyDays(
        r.daysOfMonth[0],
        r.daysOfMonth[1],
      );
    } else if (r.daysOfMonth.isNotEmpty) {
      when = '${r.daysOfMonth.first}';
    } else {
      when = '—';
    }
    lines.add('${c.name}: $amt · $cadence · $when');
  }
  return lines.isEmpty ? '—' : lines.join('\n');
}
