import 'package:flutter/material.dart';

/// Single-select pills (segmented control style).
class PillToggleGroup<T extends Object> extends StatelessWidget {
  const PillToggleGroup({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final v in values) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labelOf(v)),
                selected: v == selected,
                onSelected: (_) => onChanged(v),
                showCheckmark: false,
                labelStyle: theme.textTheme.labelLarge,
                selectedColor: theme.colorScheme.primaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
