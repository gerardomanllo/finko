import 'package:flutter/material.dart';

/// Top search + filter affordance for transaction lists.
class FinkoSearchFilterBar extends StatelessWidget {
  const FinkoSearchFilterBar({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onFilterTap,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        IconButton.filledTonal(
          onPressed: onFilterTap,
          icon: const Icon(Icons.filter_list),
        ),
      ],
    );
  }
}
