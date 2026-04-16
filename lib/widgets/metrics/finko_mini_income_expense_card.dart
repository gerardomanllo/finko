import 'package:flutter/material.dart';

/// Two columns (income | expense) “graph-ish” vertical mini bars.
class FinkoMiniIncomeExpenseCard extends StatelessWidget {
  const FinkoMiniIncomeExpenseCard({
    super.key,
    required this.bottomLabel,
    required this.incomeFraction,
    required this.expenseFraction,
    this.incomeColor,
    this.expenseColor,
  });

  final String bottomLabel;
  final double incomeFraction;
  final double expenseFraction;
  final Color? incomeColor;
  final Color? expenseColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inc = incomeFraction.clamp(0.05, 1.0);
    final exp = expenseFraction.clamp(0.05, 1.0);
    final ic = incomeColor ?? theme.colorScheme.primary;
    final ec = expenseColor ?? theme.colorScheme.tertiary;
    return SizedBox(
      width: 96,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.75,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: inc,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ic.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: exp,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ec.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bottomLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
