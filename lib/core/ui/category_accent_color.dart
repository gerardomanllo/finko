import 'package:flutter/material.dart';

import '../data/models/finko_category.dart';

/// Resolved accent for category-driven UI (list avatars, rings, donut fallbacks).
///
/// When [colorArgb] is set, returns [Color] from it. Otherwise uses the same
/// theme slots as the spending donut, keyed deterministically by [categoryId].
Color categoryAccentColor(
  ColorScheme scheme,
  String categoryId, {
  int? colorArgb,
}) {
  if (colorArgb != null) return Color(colorArgb);
  final palette = <Color>[
    scheme.primary,
    scheme.secondary,
    scheme.tertiary,
    scheme.primaryContainer,
    scheme.secondaryContainer,
  ];
  final i = categoryId.isEmpty ? 0 : categoryId.hashCode.abs() % palette.length;
  return palette[i];
}

/// Uses [category]’s stored color or id-based fallback; if [category] is null,
/// returns [scheme.primary] (caller may substitute another neutral).
Color categoryAccentColorForCategory(
  FinkoCategory? category,
  ColorScheme scheme,
) {
  if (category == null) return scheme.primary;
  return categoryAccentColor(
    scheme,
    category.id,
    colorArgb: category.colorArgb,
  );
}
