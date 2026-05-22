import 'package:flutter/material.dart';

import '../../../core/theme/finko_theme.dart';

/// Playful per-concept accent colors used across the onboarding flow.
/// Chosen to harmonize with the Finko brand blue while adding warmth/variety.
abstract final class OnboardingAccents {
  static const Color accounts = FinkoColors.primary; // brand blue
  static const Color transactions = Color(0xFF12B5B0); // teal
  static const Color categories = Color(0xFF7C5CFC); // violet
  static const Color budgets = Color(0xFFF2A33C); // amber
  static const Color income = FinkoColors.income; // green
}

/// A rounded, tinted circular container holding an icon — gives lists and
/// cards a friendly pop of color instead of flat monochrome glyphs.
class OnboardingIconChip extends StatelessWidget {
  const OnboardingIconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// One option in [OnboardingSegmentedToggle].
class OnboardingToggleOption<T> {
  const OnboardingToggleOption(this.value, this.label, [this.icon]);

  final T value;
  final String label;
  final IconData? icon;
}

/// Label + control stack for profile preference pickers.
class OnboardingToggleField extends StatelessWidget {
  const OnboardingToggleField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Single-select segmented control (theme, locale, currency) — replaces dropdowns.
class OnboardingSegmentedToggle<T> extends StatelessWidget {
  const OnboardingSegmentedToggle({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<OnboardingToggleOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: FinkoColors.cloud,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _SegmentButton<T>(
                  option: options[i],
                  selected: options[i].value == value,
                  onTap: () => onChanged(options[i].value),
                  labelStyle: textTheme.labelMedium,
                  scheme: scheme,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.labelStyle,
    required this.scheme,
  });

  final OnboardingToggleOption<T> option;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? labelStyle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                Icon(option.icon, size: 20, color: fg),
                const SizedBox(height: 4),
              ],
              Text(
                option.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: labelStyle?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact metric tile for projected-savings and review summaries.
class OnboardingMetricTile extends StatelessWidget {
  const OnboardingMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final Color? accent;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (accent ?? theme.colorScheme.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (accent ?? theme.colorScheme.primary).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style:
                (emphasis
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleMedium)
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Single-select chip with visible contrast on Finko's white/card surfaces.
class OnboardingChoiceChip extends StatelessWidget {
  const OnboardingChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.accent,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: accentColor.withValues(alpha: 0.16),
      backgroundColor: FinkoColors.cloud,
      side: BorderSide(
        color: selected
            ? accentColor.withValues(alpha: 0.55)
            : FinkoColors.grayLight,
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? accentColor : FinkoColors.grayDark,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}

/// Kind badge for income vs expense rows in onboarding lists.
class OnboardingKindBadge extends StatelessWidget {
  const OnboardingKindBadge({
    super.key,
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Section card with a tinted icon header — used on review / finalize.
class OnboardingSectionCard extends StatelessWidget {
  const OnboardingSectionCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                OnboardingIconChip(icon: icon, color: accent, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
