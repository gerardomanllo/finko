import '../spending/fixed_variable_expense.dart' show kFixedExpensesCategoryId;

/// Reserved category id for both legs of internal transfers ([`docs/data-model.md`] §4).
///
/// Document is created at onboarding commit and may be ensured by the client for
/// older accounts. Hidden from category pickers and `/categories` list.
const String kLedgerTransferCategoryId = 'ledger-transfer';

/// System category ids that are not user-deletable and may be hidden from pickers.
bool isReservedLedgerCategoryId(String id) =>
    id == kFixedExpensesCategoryId || id == kLedgerTransferCategoryId;
