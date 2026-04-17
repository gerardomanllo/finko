import 'package:flutter/material.dart';

/// Full-width or inset “paper” surface (elevation, padding) per components inventory.
class FinkoPaperCard extends StatelessWidget {
  const FinkoPaperCard({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Avoid wrapping only [child] in Column(mainAxisSize: min): that passes an
    // unbounded max height to scrollables (e.g. ListView under RefreshIndicator).
    final Widget padded = title == null
        ? Padding(padding: padding, child: child)
        : Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          );
    final body = onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: padded,
          )
        : padded;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: margin ?? EdgeInsets.zero,
      child: body,
    );
  }
}
