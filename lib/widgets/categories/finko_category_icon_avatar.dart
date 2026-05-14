import 'package:flutter/material.dart';

import '../../core/data/models/finko_category.dart';
import '../../core/data/models/ledger_transaction.dart';
import '../../core/ui/category_accent_color.dart';
import '../../features/onboarding/presentation/onboarding_category_icons.dart';

/// Circular chip with a category [iconKey], tinted by stored or fallback accent.
class FinkoCategoryIconAvatar extends StatelessWidget {
  const FinkoCategoryIconAvatar({
    super.key,
    required this.iconKey,
    required this.categoryId,
    this.colorArgb,
    this.radius = 21,
    this.iconSize,
  });

  final String iconKey;
  final String categoryId;
  final int? colorArgb;
  final double radius;
  final double? iconSize;

  factory FinkoCategoryIconAvatar.fromCategory(
    FinkoCategory category, {
    Key? key,
    double radius = 21,
    double? iconSize,
  }) {
    return FinkoCategoryIconAvatar(
      key: key,
      iconKey: category.iconKey,
      categoryId: category.id,
      colorArgb: category.colorArgb,
      radius: radius,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = categoryAccentColor(
      scheme,
      categoryId,
      colorArgb: colorArgb,
    );
    final size = iconSize ?? (radius * 0.88).clamp(17.0, 26.0);
    return _CategoryIconInCircle(
      radius: radius,
      icon: onboardingIconForKey(iconKey),
      iconSize: size,
      accent: accent,
      scheme: scheme,
    );
  }
}

/// Leading for a ledger row when the category document is missing.
Widget finkoCategoryLeadingPlaceholder(
  BuildContext context, {
  double radius = 21,
}) {
  final scheme = Theme.of(context).colorScheme;
  final size = (radius * 0.88).clamp(17.0, 26.0);
  return _CategoryIconInCircle(
    radius: radius,
    icon: Icons.help_outline,
    iconSize: size,
    accent: scheme.onSurfaceVariant,
    scheme: scheme,
  );
}

/// Outlined circle: flat, lightly tinted fill; thin ring; icon tied to accent.
class _CategoryIconInCircle extends StatelessWidget {
  const _CategoryIconInCircle({
    required this.radius,
    required this.icon,
    required this.iconSize,
    required this.accent,
    required this.scheme,
  });

  final double radius;
  final IconData icon;
  final double iconSize;
  final Color accent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final baseSurface = scheme.surfaceContainerLow;
    final fill = Color.lerp(baseSurface, accent, 0.14)!;
    final borderColor = Color.lerp(scheme.outlineVariant, accent, 0.42)!;
    final iconColor = Color.lerp(scheme.onSurfaceVariant, accent, 0.48)!;
    final d = radius * 2;
    return SizedBox(
      width: d,
      height: d,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}

/// Leading for a ledger row: resolved [FinkoCategory] when in [catById], else generic icon.
Widget ledgerTransactionCategoryLeading(
  LedgerTransaction t,
  Map<String, FinkoCategory> catById, {
  double radius = 21,
}) {
  final c = catById[t.categoryId];
  if (c != null) {
    return FinkoCategoryIconAvatar.fromCategory(c, radius: radius);
  }
  return FinkoCategoryIconAvatar(
    iconKey: 'category',
    categoryId: t.categoryId,
    colorArgb: null,
    radius: radius,
  );
}
