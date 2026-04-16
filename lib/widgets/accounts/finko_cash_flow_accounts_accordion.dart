import 'package:flutter/material.dart';

import '../../core/data/models/finko_account.dart';
import '../../core/data/models/finko_enums.dart';

/// Cash-flow ordered accordion: checking, credit, net cash (aggregate), savings, investments.
class FinkoCashFlowAccountsAccordion extends StatelessWidget {
  const FinkoCashFlowAccountsAccordion({
    super.key,
    required this.accounts,
    required this.mainCurrencyCode,
    required this.netCashMinorMain,
    required this.formatMoney,
    required this.formatMoneyWithCode,
    required this.accountTypeLabel,
    required this.netCashTitle,
  });

  final List<FinkoAccount> accounts;
  final String mainCurrencyCode;
  final int netCashMinorMain;
  final String Function(int minor, String currencyCode) formatMoney;
  final String Function(int minor, String currencyCode) formatMoneyWithCode;
  final String Function(FinkoAccountType type) accountTypeLabel;
  final String netCashTitle;

  List<FinkoAccount> _ofType(FinkoAccountType t) =>
      accounts.where((a) => a.type == t).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExpandableTypeSection(
          title: accountTypeLabel(FinkoAccountType.checking),
          accounts: _ofType(FinkoAccountType.checking),
          mainCurrencyCode: mainCurrencyCode,
          formatMoney: formatMoney,
          formatMoneyWithCode: formatMoneyWithCode,
          icon: Icons.account_balance,
        ),
        _ExpandableTypeSection(
          title: accountTypeLabel(FinkoAccountType.creditCard),
          accounts: _ofType(FinkoAccountType.creditCard),
          mainCurrencyCode: mainCurrencyCode,
          formatMoney: formatMoney,
          formatMoneyWithCode: formatMoneyWithCode,
          icon: Icons.credit_card,
        ),
        _NetCashRow(
          amountText: formatMoney(netCashMinorMain, mainCurrencyCode),
          title: netCashTitle,
        ),
        const SizedBox(height: 8),
        _ExpandableTypeSection(
          title: accountTypeLabel(FinkoAccountType.savings),
          accounts: _ofType(FinkoAccountType.savings),
          mainCurrencyCode: mainCurrencyCode,
          formatMoney: formatMoney,
          formatMoneyWithCode: formatMoneyWithCode,
          icon: Icons.savings_outlined,
        ),
        _ExpandableTypeSection(
          title: accountTypeLabel(FinkoAccountType.investment),
          accounts: _ofType(FinkoAccountType.investment),
          mainCurrencyCode: mainCurrencyCode,
          formatMoney: formatMoney,
          formatMoneyWithCode: formatMoneyWithCode,
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _NetCashRow extends StatelessWidget {
  const _NetCashRow({required this.amountText, required this.title});

  final String amountText;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
          Text(amountText, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _ExpandableTypeSection extends StatefulWidget {
  const _ExpandableTypeSection({
    required this.title,
    required this.accounts,
    required this.mainCurrencyCode,
    required this.formatMoney,
    required this.formatMoneyWithCode,
    required this.icon,
  });

  final String title;
  final List<FinkoAccount> accounts;
  final String mainCurrencyCode;
  final String Function(int minor, String currencyCode) formatMoney;
  final String Function(int minor, String currencyCode) formatMoneyWithCode;
  final IconData icon;

  @override
  State<_ExpandableTypeSection> createState() => _ExpandableTypeSectionState();
}

class _ExpandableTypeSectionState extends State<_ExpandableTypeSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sum = widget.accounts.fold<int>(
      0,
      (s, a) => s + (a.balanceMinorMain ?? a.balanceMinor),
    );
    final usesMainCurrency = widget.accounts.any(
      (a) => a.balanceMinorMain != null,
    );
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(widget.icon),
          title: Text(widget.title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.formatMoney(
                  sum,
                  usesMainCurrency
                      ? widget.mainCurrencyCode
                      : (widget.accounts.isNotEmpty
                            ? widget.accounts.first.currency
                            : widget.mainCurrencyCode),
                ),
                style: theme.textTheme.titleSmall,
              ),
              Icon(
                widget.accounts.isEmpty
                    ? Icons.expand_more
                    : (_open ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          onTap: widget.accounts.isEmpty
              ? null
              : () => setState(() => _open = !_open),
        ),
        if (_open)
          ...widget.accounts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(a.name),
                trailing: _AccountAmount(
                  mainAmountText: widget.formatMoney(
                    a.balanceMinorMain ?? a.balanceMinor,
                    widget.mainCurrencyCode,
                  ),
                  actualAmountText: a.currency == widget.mainCurrencyCode
                      ? null
                      : widget.formatMoneyWithCode(a.balanceMinor, a.currency),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountAmount extends StatelessWidget {
  const _AccountAmount({required this.mainAmountText, this.actualAmountText});

  final String mainAmountText;
  final String? actualAmountText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (actualAmountText == null) {
      return Text(mainAmountText);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('~$mainAmountText', style: theme.textTheme.bodySmall),
        Text(actualAmountText!, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
