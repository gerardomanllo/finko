import 'package:flutter/material.dart';

import '../../../core/formatting/money_format.dart';
import '../../../l10n/app_localizations.dart';

/// One expense row (fixed or variable) before sorting; [OnboardingProjectedChart] merges
/// and orders by **amount** (largest next to the $0 axis, smaller above, then savings on top).
@immutable
class OnboardingProjectedVariableSegment {
  const OnboardingProjectedVariableSegment({
    required this.label,
    required this.amountMinor,
  });

  final String label;
  final int amountMinor;
}

/// Stacked column: **expense** segments ([largest budget] … smallest) → **projected savings** (top / 100% income).
class OnboardingProjectedChart extends StatelessWidget {
  const OnboardingProjectedChart({
    super.key,
    required this.chartTotalHeight,
    required this.expectedIncomeMinor,
    required this.fixedExpensesMinor,
    required this.variableSegments,
    required this.projectedSavingsMinor,
    required this.currencyCode,
    required this.localeTag,
    required this.l10n,
    required this.fixedLabel,
    required this.savingsLabel,
  });

  /// Vertical space for the chart (axis + stacked column + labels), from parent [LayoutBuilder].
  final double chartTotalHeight;

  final int expectedIncomeMinor;
  final int fixedExpensesMinor;

  /// Non–fixed expense categories (amounts from budgets).
  final List<OnboardingProjectedVariableSegment> variableSegments;

  final int projectedSavingsMinor;
  final String currencyCode;
  final String localeTag;
  final AppLocalizations l10n;
  final String fixedLabel;
  final String savingsLabel;

  static const double _barWidth = 72;
  static const double _labelGap = 12;

  static int _sumVariable(List<OnboardingProjectedVariableSegment> segments) {
    var t = 0;
    for (final s in segments) {
      t += s.amountMinor;
    }
    return t;
  }

  /// Bottom of stack (index 0) = **largest** expense; color gets darker for larger amounts.
  static Color _expenseBlueAt(int indexFromBottom) {
    const shades = <int>[900, 800, 700, 600, 500, 400, 300];
    return Colors.blue[shades[indexFromBottom % shades.length]]!;
  }

  String _pctLabel(int segmentMinor) {
    if (expectedIncomeMinor <= 0) return '—';
    final pct = (100 * segmentMinor / expectedIncomeMinor).clamp(0, 9999.0);
    if (pct >= 10) {
      return pct.toStringAsFixed(0);
    }
    return pct.toStringAsFixed(1);
  }

  String _segmentLine(String name, int segmentMinor) {
    final amt = formatMinorUnits(segmentMinor, currencyCode, localeTag);
    return l10n.onboardingProjectedSegmentLine(
      name,
      _pctLabel(segmentMinor),
      amt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final income = expectedIncomeMinor;
    final fixed = fixedExpensesMinor;
    final variable = _sumVariable(variableSegments);
    final savings = projectedSavingsMinor;
    final overspend = savings < 0 ? (-savings) : 0;

    final chartInnerHeight = chartTotalHeight.clamp(120.0, 4000.0);

    final savingsGreen = Colors.green.shade600;
    final savingsRed = cs.error;

    // Fixed + variable rows, then **descending** by amount (largest = index 0 = next to $0).
    final expenseRows =
        <OnboardingProjectedVariableSegment>[
          OnboardingProjectedVariableSegment(
            label: fixedLabel,
            amountMinor: fixed,
          ),
          ...variableSegments,
        ]..sort((a, b) {
          final c = b.amountMinor.compareTo(a.amountMinor);
          if (c != 0) return c;
          return a.label.compareTo(b.label);
        });

    // Positive savings slice (minor) for scaling.
    final savPosMinor = savings > 0 ? savings : 0;
    final totalExpense = fixed + variable;
    final innerTotal = totalExpense + savPosMinor;
    final scale = income > 0 && innerTotal > income ? income / innerTotal : 1.0;
    final sExp = <int>[
      for (final s in expenseRows) (s.amountMinor * scale).round(),
    ];
    final sSavPos = savings > 0 ? (savPosMinor * scale).round() : 0;

    double hFor(int minor) {
      if (income <= 0) return 0.0;
      return chartInnerHeight * minor / income;
    }

    var hExp = <double>[for (final se in sExp) hFor(se)];
    var hSav = savings > 0 ? hFor(sSavPos) : 0.0;

    double sumExpenseHeights() {
      var t = 0.0;
      for (final h in hExp) {
        t += h;
      }
      return t;
    }

    if (savings < 0) {
      final overspendMinor = -savings;
      final hNeg = income > 0
          ? (chartInnerHeight * (overspendMinor / income).clamp(0.0, 0.35))
                .clamp(10.0, chartInnerHeight * 0.35)
          : 24.0;
      final remaining = (chartInnerHeight - hNeg).clamp(0.0, chartInnerHeight);
      if (totalExpense > 0 && remaining > 0) {
        for (var i = 0; i < hExp.length; i++) {
          final m = i < expenseRows.length ? expenseRows[i].amountMinor : 0;
          hExp[i] = remaining * m / totalExpense;
        }
      } else {
        hExp = [for (final _ in hExp) 0.0];
      }
      hSav = hNeg;
    } else if (savings == 0 && income > 0) {
      const minZeroSavings = 6.0;
      final expSum = sumExpenseHeights();
      final room = (chartInnerHeight - expSum - hSav).clamp(
        0.0,
        chartInnerHeight,
      );
      if (room >= minZeroSavings) {
        hSav = (chartInnerHeight - expSum).clamp(0.0, chartInnerHeight);
      } else {
        hSav = minZeroSavings.clamp(0.0, chartInnerHeight);
        var shrink = expSum + hSav - chartInnerHeight;
        if (shrink > 0 && totalExpense > 0) {
          for (var i = 0; i < hExp.length; i++) {
            final m = i < expenseRows.length ? expenseRows[i].amountMinor : 0;
            hExp[i] -= shrink * (m / totalExpense);
          }
        }
      }
    }

    Color savingsColor() {
      if (savings > 0) return savingsGreen;
      if (savings < 0) return savingsRed;
      return cs.surfaceContainerHighest;
    }

    Widget band(double h, Color color, String label) {
      if (h <= 0) return const SizedBox.shrink();
      return SizedBox(
        height: h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: _barWidth,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: _labelGap),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final savingsLine = savings < 0
        ? l10n.onboardingProjectedOverspendLine(
            formatMinorUnits(overspend, currencyCode, localeTag),
          )
        : _segmentLine(savingsLabel, savings);

    // Column renders children top → bottom; we want SAVINGS at the top (near expected-income line)
    // and the LARGEST expense pinned to the $0 axis, smaller expenses stacked between.
    final stackChildren = <Widget>[
      band(
        hSav,
        savingsColor(),
        savings == 0 ? _segmentLine(savingsLabel, 0) : savingsLine,
      ),
      for (var i = expenseRows.length - 1; i >= 0; i--)
        band(
          i < hExp.length ? hExp[i] : 0.0,
          _expenseBlueAt(i),
          _segmentLine(expenseRows[i].label, expenseRows[i].amountMinor),
        ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 52,
          height: chartInnerHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (income > 0)
                Text(
                  formatMinorUnits(income, currencyCode, localeTag),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                )
              else
                const SizedBox.shrink(),
              Text(
                formatMinorUnits(0, currencyCode, localeTag),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: chartInnerHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: stackChildren,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
