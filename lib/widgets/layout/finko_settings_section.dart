import 'package:flutter/material.dart';

/// Section title + child (settings / preferences lists).
class FinkoSettingsSection extends StatelessWidget {
  const FinkoSettingsSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
