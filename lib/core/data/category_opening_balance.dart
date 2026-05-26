import 'models/finko_category.dart';
import 'models/finko_enums.dart';

/// Lowest [FinkoCategory.sortOrder] expense category (opening-balance adjustments).
String? firstExpenseCategoryIdBySortOrder(Iterable<FinkoCategory> categories) {
  final expenses =
      categories.where((c) => c.kind == CategoryKind.expense).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return expenses.isEmpty ? null : expenses.first.id;
}
