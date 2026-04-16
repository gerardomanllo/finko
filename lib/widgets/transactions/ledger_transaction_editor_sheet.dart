import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/firebase_auth_providers.dart';
import '../../core/data/models/finko_account.dart';
import '../../core/data/models/finko_category.dart';
import '../../core/data/models/finko_enums.dart';
import '../../core/data/models/ledger_transaction.dart';
import '../../core/data/providers/finko_stream_providers.dart';
import '../../core/data/repositories/firestore_data_repository.dart';
import '../../core/formatting/amount_input.dart';
import '../../features/transactions/application/transactions_list_notifier.dart';
import '../../l10n/app_localizations.dart';

/// Slide-up create/edit ledger transaction ([`docs/data-model.md`] §4). No route.
///
/// - Income/expense rows are always **`standard`** (or **`adjustment`** when editing an
///   existing adjustment — never created from this UI).
/// - **Transfers** use two accounts (from → to); the app writes both **`transferLeg`**
///   documents in one batch.
class LedgerTransactionEditorSheet extends ConsumerStatefulWidget {
  const LedgerTransactionEditorSheet({super.key, this.transaction});

  /// `null` = create; non-null = edit existing row.
  final LedgerTransaction? transaction;

  static Future<void> show(
    BuildContext context, {
    LedgerTransaction? transaction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => LedgerTransactionEditorSheet(transaction: transaction),
    );
  }

  @override
  ConsumerState<LedgerTransactionEditorSheet> createState() =>
      _LedgerTransactionEditorSheetState();
}

enum _SheetMode { incomeExpense, transfer }

class _LedgerTransactionEditorSheetState
    extends ConsumerState<LedgerTransactionEditorSheet> {
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  late String _dateYmd;
  MoneyDirection _direction = MoneyDirection.out_;
  String? _accountId;
  String? _categoryId;

  /// Transfer: money leaves [from] and enters [to].
  String? _fromAccountId;
  String? _toAccountId;

  late _SheetMode _sheetMode;
  LedgerTransaction? _peerLeg;
  bool _peerLoadDone = true;

  bool _saving = false;
  bool _deleting = false;
  bool _didPickDefaultAccount = false;
  bool _didPickDefaultTransferAccounts = false;

  /// After the first failed save, invalid fields show error styling until the user fixes them.
  bool _submitAttempted = false;

  bool get _editing => widget.transaction != null;

  bool get _isTransferContext =>
      _sheetMode == _SheetMode.transfer ||
      (widget.transaction?.type == LedgerTransactionKind.transferLeg);

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _dateYmd = t.transactionDate;
      _amountController.text = _minorToDecimalString(t.amountMinor);
      _memoController.text = t.memo ?? '';
      if (t.type == LedgerTransactionKind.transferLeg) {
        _sheetMode = _SheetMode.transfer;
        _direction = t.direction;
        _peerLoadDone = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadPeerLeg());
      } else {
        _sheetMode = _SheetMode.incomeExpense;
        _direction = t.direction;
        _accountId = t.accountId;
        _categoryId = t.categoryId;
      }
    } else {
      _sheetMode = _SheetMode.incomeExpense;
      _dateYmd = DateFormat('yyyy-MM-dd').format(DateTime.now());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _dateYmd = ref.read(todayYyyyMmDdProvider);
        });
      });
    }
    _amountController.addListener(_onAmountChanged);
  }

  Future<void> _loadPeerLeg() async {
    final t = widget.transaction;
    final uid = ref.read(authUidProvider);
    if (t == null || uid == null || t.linkedTransactionId == null) {
      if (mounted) setState(() => _peerLoadDone = true);
      return;
    }
    final peer = await ref
        .read(firestoreDataRepositoryProvider)
        .fetchTransaction(uid, t.linkedTransactionId!);
    if (!mounted) return;
    setState(() {
      _peerLeg = peer;
      if (peer != null) {
        if (t.direction == MoneyDirection.out_) {
          _fromAccountId = t.accountId;
          _toAccountId = peer.accountId;
        } else {
          _fromAccountId = peer.accountId;
          _toAccountId = t.accountId;
        }
      }
      _peerLoadDone = true;
    });
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  static String _minorToDecimalString(int minor) =>
      (minor / 100.0).toStringAsFixed(2);

  static DateTime _parseYmd(String ymd) {
    final p = ymd.split('-');
    if (p.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(p[0]) ?? 2000,
      int.tryParse(p[1]) ?? 1,
      int.tryParse(p[2]) ?? 1,
    );
  }

  static bool _isValidCalendarDateYmd(String s) {
    final re = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final m = re.firstMatch(s.trim());
    if (m == null) return false;
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final d = int.tryParse(m.group(3)!);
    if (y == null || mo == null || d == null) return false;
    final dt = DateTime(y, mo, d);
    return dt.year == y && dt.month == mo && dt.day == d;
  }

  LedgerTransactionKind _ledgerKindForIncomeExpenseSave() {
    if (_editing &&
        widget.transaction!.type == LedgerTransactionKind.adjustment) {
      return LedgerTransactionKind.adjustment;
    }
    return LedgerTransactionKind.standard;
  }

  String? _amountErrorText(AppLocalizations l10n) {
    if (!_submitAttempted) return null;
    try {
      parseAmountStringToMinorUnits(_amountController.text);
      return null;
    } catch (_) {
      return l10n.transactionEditorValidationAmount;
    }
  }

  String? _accountErrorText(
    AppLocalizations l10n,
    List<FinkoAccount> accounts,
  ) {
    if (!_submitAttempted) return null;
    if (_accountId == null) return l10n.transactionEditorValidationAccount;
    if (_accountFor(accounts, _accountId) == null) {
      return l10n.transactionEditorValidationAccount;
    }
    return null;
  }

  String? _dateErrorText(AppLocalizations l10n) {
    if (!_submitAttempted) return null;
    if (_isValidCalendarDateYmd(_dateYmd)) return null;
    return l10n.transactionEditorValidationDate;
  }

  String? _categoryErrorText(
    AppLocalizations l10n,
    List<FinkoCategory> filteredCats,
  ) {
    if (!_submitAttempted) return null;
    if (filteredCats.isEmpty) {
      return l10n.transactionEditorValidationCategoryEmpty;
    }
    if (_categoryId == null || !filteredCats.any((c) => c.id == _categoryId)) {
      return l10n.transactionEditorValidationCategory;
    }
    return null;
  }

  String? _fromAccountErrorText(
    AppLocalizations l10n,
    List<FinkoAccount> accounts,
  ) {
    if (!_submitAttempted || !_isTransferContext) return null;
    if (_fromAccountId == null) {
      return l10n.transactionEditorValidationFromAccount;
    }
    if (_accountFor(accounts, _fromAccountId) == null) {
      return l10n.transactionEditorValidationFromAccount;
    }
    return null;
  }

  String? _toAccountErrorText(
    AppLocalizations l10n,
    List<FinkoAccount> accounts,
  ) {
    if (!_submitAttempted || !_isTransferContext) return null;
    if (_toAccountId == null) {
      return l10n.transactionEditorValidationToAccount;
    }
    if (_accountFor(accounts, _toAccountId) == null) {
      return l10n.transactionEditorValidationToAccount;
    }
    return null;
  }

  String? _transferPairErrorText(
    AppLocalizations l10n,
    List<FinkoAccount> accounts,
  ) {
    if (!_submitAttempted || !_isTransferContext) return null;
    final from = _accountFor(accounts, _fromAccountId);
    final to = _accountFor(accounts, _toAccountId);
    if (from != null && to != null && from.id == to.id) {
      return l10n.transactionEditorValidationTransferDistinctAccounts;
    }
    if (from != null && to != null && from.currency != to.currency) {
      return l10n.transactionEditorValidationTransferSameCurrency;
    }
    return null;
  }

  bool _categoryIdInFiltered(List<FinkoCategory> filtered) {
    if (_categoryId == null) return false;
    return filtered.any((c) => c.id == _categoryId);
  }

  FinkoAccount? _accountFor(List<FinkoAccount> accounts, String? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<FinkoCategory> _categoriesForDirection(
    List<FinkoCategory> all,
    MoneyDirection d,
  ) {
    final want = d == MoneyDirection.in_
        ? CategoryKind.income
        : CategoryKind.expense;
    return all.where((c) => c.kind == want).toList();
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context);
    final initial = _parseYmd(_dateYmd);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: l10n.transactionEditorFieldDate,
    );
    if (picked != null) {
      setState(() {
        _dateYmd = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _invalidateAfterWrite() {
    ref.invalidate(recentTransactionsStreamProvider);
    ref.invalidate(transactionsListNotifierProvider);
    ref.invalidate(currentMonthTotalsStreamProvider);
    ref.invalidate(accountsStreamProvider);
  }

  void _applyDefaultTransferAccountsIfNeeded(List<FinkoAccount> accounts) {
    if (_sheetMode != _SheetMode.transfer ||
        _editing ||
        _didPickDefaultTransferAccounts ||
        accounts.length < 2) {
      return;
    }
    _didPickDefaultTransferAccounts = true;
    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _fromAccountId = accounts[0].id;
        _toAccountId = accounts[1].id;
      });
    });
  }

  Future<void> _save() async {
    if (_isTransferContext) {
      await _saveTransfer();
    } else {
      await _saveIncomeExpense();
    }
  }

  Future<void> _saveIncomeExpense() async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authUidProvider);
    if (uid == null || _saving) return;

    final accounts = ref.read(accountsStreamProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesStreamProvider).valueOrNull ?? [];
    final filteredCats = _categoriesForDirection(categories, _direction);

    setState(() => _submitAttempted = true);

    if (!_isValidCalendarDateYmd(_dateYmd)) return;

    late final int minor;
    try {
      minor = parseAmountStringToMinorUnits(_amountController.text);
    } catch (_) {
      return;
    }

    final acc = _accountFor(accounts, _accountId);
    if (_accountId == null || acc == null) return;

    if (filteredCats.isEmpty ||
        _categoryId == null ||
        !filteredCats.any((c) => c.id == _categoryId)) {
      return;
    }
    final categoryId = _categoryId!;
    final kind = _ledgerKindForIncomeExpenseSave();

    setState(() {
      _submitAttempted = false;
      _saving = true;
    });
    try {
      final repo = ref.read(firestoreDataRepositoryProvider);
      final memoTrim = _memoController.text.trim();
      final memo = memoTrim.isEmpty ? null : memoTrim;

      if (_editing) {
        final prev = widget.transaction!;
        final next = LedgerTransaction(
          id: prev.id,
          transactionDate: _dateYmd,
          loadedAt: prev.loadedAt,
          amountMinor: minor,
          direction: _direction,
          currency: acc.currency,
          accountId: _accountId!,
          categoryId: categoryId,
          type: kind,
          memo: memo,
          transferGroupId: null,
          linkedTransactionId: null,
          sourceUpcomingId: prev.sourceUpcomingId,
          amountMinorMain: prev.amountMinorMain,
          fxRateDateUsed: prev.fxRateDateUsed,
          createdAt: prev.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
        await repo.updateTransaction(uid, next);
      } else {
        final placeholder = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final draft = LedgerTransaction(
          id: '',
          transactionDate: _dateYmd,
          loadedAt: placeholder,
          amountMinor: minor,
          direction: _direction,
          currency: acc.currency,
          accountId: _accountId!,
          categoryId: categoryId,
          type: LedgerTransactionKind.standard,
          memo: memo,
          transferGroupId: null,
          linkedTransactionId: null,
          sourceUpcomingId: null,
          amountMinorMain: null,
          fxRateDateUsed: null,
          createdAt: placeholder,
          updatedAt: placeholder,
        );
        await repo.createTransaction(uid, draft);
      }
      _invalidateAfterWrite();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.transactionEditorErrorSave} ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  LedgerTransaction _buildUpdatedTransferLeg({
    required LedgerTransaction prev,
    required String transactionDate,
    required int amountMinor,
    required String accountId,
    required String currency,
    required MoneyDirection direction,
    required String linkedId,
    required String groupId,
    String? memo,
  }) {
    return LedgerTransaction(
      id: prev.id,
      transactionDate: transactionDate,
      loadedAt: prev.loadedAt,
      amountMinor: amountMinor,
      direction: direction,
      currency: currency,
      accountId: accountId,
      categoryId: null,
      type: LedgerTransactionKind.transferLeg,
      memo: memo,
      transferGroupId: groupId,
      linkedTransactionId: linkedId,
      sourceUpcomingId: prev.sourceUpcomingId,
      amountMinorMain: prev.amountMinorMain,
      fxRateDateUsed: prev.fxRateDateUsed,
      createdAt: prev.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> _saveTransfer() async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authUidProvider);
    if (uid == null || _saving) return;

    if (_editing &&
        (widget.transaction?.linkedTransactionId == null || _peerLeg == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.transactionEditorErrorSave)));
      return;
    }

    final accounts = ref.read(accountsStreamProvider).valueOrNull ?? [];

    setState(() => _submitAttempted = true);

    if (!_isValidCalendarDateYmd(_dateYmd)) return;

    late final int minor;
    try {
      minor = parseAmountStringToMinorUnits(_amountController.text);
    } catch (_) {
      return;
    }

    final fromAcc = _accountFor(accounts, _fromAccountId);
    final toAcc = _accountFor(accounts, _toAccountId);
    if (fromAcc == null || toAcc == null) return;
    if (_transferPairErrorText(l10n, accounts) != null) return;

    setState(() {
      _submitAttempted = false;
      _saving = true;
    });

    try {
      final repo = ref.read(firestoreDataRepositoryProvider);
      final memoTrim = _memoController.text.trim();
      final memo = memoTrim.isEmpty ? null : memoTrim;

      if (_editing) {
        final cur = widget.transaction!;
        final peer = _peerLeg!;
        final groupId = cur.transferGroupId ?? peer.transferGroupId;
        if (groupId == null || groupId.isEmpty) {
          throw StateError('transferGroupId missing');
        }

        final outPrev = cur.direction == MoneyDirection.out_ ? cur : peer;
        final inPrev = cur.direction == MoneyDirection.out_ ? peer : cur;

        final outNext = _buildUpdatedTransferLeg(
          prev: outPrev,
          transactionDate: _dateYmd,
          amountMinor: minor,
          accountId: _fromAccountId!,
          currency: fromAcc.currency,
          direction: MoneyDirection.out_,
          linkedId: inPrev.id,
          groupId: groupId,
          memo: memo,
        );
        final inNext = _buildUpdatedTransferLeg(
          prev: inPrev,
          transactionDate: _dateYmd,
          amountMinor: minor,
          accountId: _toAccountId!,
          currency: toAcc.currency,
          direction: MoneyDirection.in_,
          linkedId: outPrev.id,
          groupId: groupId,
          memo: memo,
        );
        await repo.updateTransferLegPair(uid, outNext, inNext);
      } else {
        await repo.createTransferLegPair(
          uid,
          transactionDate: _dateYmd,
          amountMinor: minor,
          fromAccountId: _fromAccountId!,
          toAccountId: _toAccountId!,
          currency: fromAcc.currency,
          memo: memo,
        );
      }
      _invalidateAfterWrite();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.transactionEditorErrorSave} ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(authUidProvider);
    final id = widget.transaction?.id;
    if (uid == null || id == null || _deleting) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.transactionEditorDeleteConfirmTitle),
        content: Text(l10n.transactionEditorDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.transactionEditorCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.transactionEditorDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(firestoreDataRepositoryProvider)
          .deleteTransaction(uid, id);
      _invalidateAfterWrite();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.transactionEditorErrorDelete} ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _syncCategoryAfterDirectionChange(List<FinkoCategory> filtered) {
    if (_categoryId != null && !filtered.any((c) => c.id == _categoryId)) {
      _categoryId = null;
    }
  }

  Widget _buildModeSelector(AppLocalizations l10n, ThemeData theme) {
    final t = widget.transaction;
    if (_editing && t?.type == LedgerTransactionKind.transferLeg) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.transactionEditorEntryTransfer,
          style: theme.textTheme.labelLarge,
        ),
      );
    }

    if (_editing) {
      return Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: Text(l10n.transactionEditorDirectionIn),
              selected:
                  _sheetMode == _SheetMode.incomeExpense &&
                  _direction == MoneyDirection.in_,
              onSelected: (_) {
                final c =
                    ref.read(categoriesStreamProvider).valueOrNull ??
                    <FinkoCategory>[];
                final f = _categoriesForDirection(c, MoneyDirection.in_);
                setState(() {
                  _sheetMode = _SheetMode.incomeExpense;
                  _direction = MoneyDirection.in_;
                  _syncCategoryAfterDirectionChange(f);
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: Text(l10n.transactionEditorDirectionOut),
              selected:
                  _sheetMode == _SheetMode.incomeExpense &&
                  _direction == MoneyDirection.out_,
              onSelected: (_) {
                final c =
                    ref.read(categoriesStreamProvider).valueOrNull ??
                    <FinkoCategory>[];
                final f = _categoriesForDirection(c, MoneyDirection.out_);
                setState(() {
                  _sheetMode = _SheetMode.incomeExpense;
                  _direction = MoneyDirection.out_;
                  _syncCategoryAfterDirectionChange(f);
                });
              },
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: Text(l10n.transactionEditorDirectionIn),
            selected:
                _sheetMode == _SheetMode.incomeExpense &&
                _direction == MoneyDirection.in_,
            onSelected: (_) {
              final c =
                  ref.read(categoriesStreamProvider).valueOrNull ??
                  <FinkoCategory>[];
              final f = _categoriesForDirection(c, MoneyDirection.in_);
              final wasTransfer = _sheetMode == _SheetMode.transfer;
              setState(() {
                _sheetMode = _SheetMode.incomeExpense;
                _direction = MoneyDirection.in_;
                if (wasTransfer) {
                  _accountId = null;
                  _didPickDefaultAccount = false;
                }
                _syncCategoryAfterDirectionChange(f);
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: Text(l10n.transactionEditorDirectionOut),
            selected:
                _sheetMode == _SheetMode.incomeExpense &&
                _direction == MoneyDirection.out_,
            onSelected: (_) {
              final c =
                  ref.read(categoriesStreamProvider).valueOrNull ??
                  <FinkoCategory>[];
              final f = _categoriesForDirection(c, MoneyDirection.out_);
              final wasTransfer = _sheetMode == _SheetMode.transfer;
              setState(() {
                _sheetMode = _SheetMode.incomeExpense;
                _direction = MoneyDirection.out_;
                if (wasTransfer) {
                  _accountId = null;
                  _didPickDefaultAccount = false;
                }
                _syncCategoryAfterDirectionChange(f);
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: Text(l10n.transactionEditorEntryTransfer),
            selected: _sheetMode == _SheetMode.transfer,
            onSelected: (_) {
              setState(() {
                _sheetMode = _SheetMode.transfer;
                _categoryId = null;
                _didPickDefaultTransferAccounts = false;
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final title = _editing
        ? l10n.transactionEditorSheetEditTitle
        : l10n.newTransactionSheetTitle;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            if (!_editing) ...[
              const SizedBox(height: 6),
              Text(
                l10n.newTransactionSheetBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_editing && widget.transaction != null) ...[
              const SizedBox(height: 6),
              Text(
                '${widget.transaction!.transactionDate} · ${widget.transaction!.id}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return Text(l10n.transactionEditorValidationAccount);
                }

                if (_sheetMode == _SheetMode.incomeExpense) {
                  if (_accountId == null &&
                      !_didPickDefaultAccount &&
                      accounts.isNotEmpty) {
                    _didPickDefaultAccount = true;
                    Future.microtask(() {
                      if (mounted) {
                        setState(() => _accountId = accounts.first.id);
                      }
                    });
                  }
                } else {
                  _applyDefaultTransferAccountsIfNeeded(accounts);
                }

                final cats = categoriesAsync.valueOrNull ?? [];
                final filteredCats = _categoriesForDirection(cats, _direction);
                final showTransferForm = _isTransferContext;

                if (_editing &&
                    widget.transaction?.type ==
                        LedgerTransactionKind.transferLeg &&
                    !_peerLoadDone) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.transactionEditorFieldDate,
                            border: const OutlineInputBorder(),
                            errorText: _dateErrorText(l10n),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(_dateYmd)),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.transactionEditorFieldAmount,
                        border: const OutlineInputBorder(),
                        errorText: _amountErrorText(l10n),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.transactionEditorFieldDirection,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildModeSelector(l10n, theme),
                    const SizedBox(height: 12),
                    if (showTransferForm) ...[
                      Builder(
                        builder: (context) {
                          final toAccounts = accounts
                              .where(
                                (a) =>
                                    _fromAccountId == null ||
                                    a.id != _fromAccountId,
                              )
                              .toList();
                          final fromValue =
                              _fromAccountId != null &&
                                  accounts.any((a) => a.id == _fromAccountId)
                              ? _fromAccountId
                              : null;
                          final toValue =
                              _toAccountId != null &&
                                  toAccounts.any((a) => a.id == _toAccountId)
                              ? _toAccountId
                              : null;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: fromValue,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.transactionEditorFieldFromAccount,
                                  border: const OutlineInputBorder(),
                                  errorText:
                                      _fromAccountErrorText(l10n, accounts) ??
                                      _transferPairErrorText(l10n, accounts),
                                ),
                                items: [
                                  for (final a in accounts)
                                    DropdownMenuItem(
                                      value: a.id,
                                      child: Text(a.name),
                                    ),
                                ],
                                onChanged: (v) => setState(() {
                                  _fromAccountId = v;
                                  if (v != null && v == _toAccountId) {
                                    _toAccountId = null;
                                  }
                                }),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: toValue,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.transactionEditorFieldToAccount,
                                  border: const OutlineInputBorder(),
                                  errorText:
                                      _toAccountErrorText(l10n, accounts) ??
                                      _transferPairErrorText(l10n, accounts),
                                ),
                                items: [
                                  for (final a in toAccounts)
                                    DropdownMenuItem(
                                      value: a.id,
                                      child: Text(a.name),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _toAccountId = v),
                              ),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value:
                            _accountId != null &&
                                accounts.any((a) => a.id == _accountId)
                            ? _accountId
                            : null,
                        decoration: InputDecoration(
                          labelText: l10n.transactionEditorFieldAccount,
                          border: const OutlineInputBorder(),
                          errorText: _accountErrorText(l10n, accounts),
                        ),
                        items: [
                          for (final a in accounts)
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                        ],
                        onChanged: (v) => setState(() => _accountId = v),
                      ),
                      const SizedBox(height: 12),
                      if (filteredCats.isEmpty)
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.transactionEditorFieldCategory,
                            border: const OutlineInputBorder(),
                            errorText: _categoryErrorText(l10n, filteredCats),
                          ),
                          child: SizedBox(
                            height: 24,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(
                                Icons.category_outlined,
                                size: 22,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String?>(
                          // ignore: deprecated_member_use
                          value: _categoryIdInFiltered(filteredCats)
                              ? _categoryId
                              : null,
                          hint: Text(l10n.transactionEditorCategoryHint),
                          decoration: InputDecoration(
                            labelText: l10n.transactionEditorFieldCategory,
                            border: const OutlineInputBorder(),
                            errorText: _categoryErrorText(l10n, filteredCats),
                          ),
                          items: [
                            for (final c in filteredCats)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _memoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.transactionEditorFieldMemo,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: (_saving || _deleting) ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.transactionEditorSave),
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: (_saving || _deleting)
                            ? null
                            : _confirmDelete,
                        child: _deleting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.transactionEditorDelete),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }
}
