import '../data/models/finko_category.dart';
import '../data/models/finko_enums.dart';

/// Maps signed [`MonthlyTotals.byCategoryMinorMain`] to **positive** expense
/// minor per `categoryId` (only keys that are expense categories in [categories]).
Map<String, int> positiveExpenseByCategoryId({
  required Map<String, int> signedByCategoryMinorMain,
  required List<FinkoCategory> categories,
}) {
  final expenseIds = {
    for (final c in categories)
      if (c.kind == CategoryKind.expense) c.id,
  };
  final out = <String, int>{};
  for (final e in signedByCategoryMinorMain.entries) {
    if (!expenseIds.contains(e.key)) continue;
    if (e.value >= 0) continue;
    out[e.key] = -e.value;
  }
  return out;
}
