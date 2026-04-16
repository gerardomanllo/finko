import 'package:flutter/material.dart';

/// Top search + filter affordance for transaction lists.
class FinkoSearchFilterBar extends StatelessWidget {
  const FinkoSearchFilterBar({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onFilterTap,
    this.filterTooltip,
    this.belowSearch,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  /// Shown as [Tooltip] on the filter button (active filter label).
  final String? filterTooltip;

  /// Optional row under the search field (e.g. history scan status).
  final Widget? belowSearch;

  @override
  Widget build(BuildContext context) {
    final filterButton = IconButton.filledTonal(
      onPressed: onFilterTap,
      icon: const Icon(Icons.filter_list),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            filterTooltip == null
                ? filterButton
                : Tooltip(message: filterTooltip!, child: filterButton),
          ],
        ),
        if (belowSearch != null) ...[const SizedBox(height: 8), belowSearch!],
      ],
    );
  }
}
