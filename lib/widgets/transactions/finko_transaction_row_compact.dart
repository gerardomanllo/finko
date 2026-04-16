import 'package:flutter/material.dart';

/// List row: leading icon/avatar, title, subtitle, trailing amount.
class FinkoTransactionRowCompact extends StatelessWidget {
  const FinkoTransactionRowCompact({
    super.key,
    required this.title,
    this.subtitle,
    required this.amountText,
    this.secondaryAmountText,
    this.leading,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String amountText;
  final String? secondaryAmountText;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
      leading:
          leading ??
          CircleAvatar(
            radius: 18,
            child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?'),
          ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodySmall)
          : null,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amountText,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (secondaryAmountText != null)
            Text(
              secondaryAmountText!,
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
