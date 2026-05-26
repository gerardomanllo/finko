/// Reserved category id for both legs of internal transfers ([`docs/data-model.md`] §4).
const String kLedgerTransferCategoryId = 'ledger-transfer';

/// System category ids that are not user-deletable and may be hidden from pickers.
bool isReservedLedgerCategoryId(String id) => id == kLedgerTransferCategoryId;
