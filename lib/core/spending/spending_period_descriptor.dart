import 'spending_granularity.dart';

/// One selectable period card: inclusive business-date range + stable ids.
class SpendingPeriodDescriptor {
  const SpendingPeriodDescriptor({
    required this.granularity,
    required this.startYyyyMmDd,
    required this.endYyyyMmDd,
    required this.key,
  });

  final SpendingGranularity granularity;

  /// Inclusive [`docs/data-model.md`] `transactionDate` range.
  final String startYyyyMmDd;
  final String endYyyyMmDd;

  /// Stable key for selection / `ListView` keys.
  final String key;
}
