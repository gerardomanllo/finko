import 'package:flutter/material.dart';

import '../../core/data/models/finko_account.dart';
import '../../core/data/models/finko_enums.dart';

/// Cash-flow ordered accordion: checking, credit, net cash (aggregate), savings, investments.
class FinkoCashFlowAccountsAccordion extends StatelessWidget {
  const FinkoCashFlowAccountsAccordion({
    super.key,
    required this.accounts,
    required this.netCashMinorMain,
    required this.formatMoney,
    required this.accountTypeLabel,
    required this.netCashTitle,
    required this.otherLiabilitiesTitle,
  });

  final List<FinkoAccount> accounts;
  final int netCashMinorMain;
  final String Function(int minor, String currencyCode) formatMoney;
  final String Function(FinkoAccountType type) accountTypeLabel;
  final String netCashTitle;
  final String otherLiabilitiesTitle;

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
          formatMoney: formatMoney,
          icon: Icons.account_balance,
        ),
        _ExpandableTypeSection(
          title: accountTypeLabel(FinkoAccountType.creditCard),
          accounts: _ofType(FinkoAccountType.creditCard),
          formatMoney: formatMoney,
          icon: Icons.credit_card,
        ),
        _NetCashRow(
          amountText: formatMoney(netCashMinorMain, _mainCurrency(accounts)),
          title: netCashTitle,
        ),
        const SizedBox(height: 8),
        _ExpandableTypeSection(
          title: accountTypeLabel(FinkoAccountType.savings),
          accounts: _ofType(FinkoAccountType.savings),
          formatMoney: formatMoney,
          icon: Icons.savings_outlined,
        ),
        _ExpandableTypeSection(
          title: accountTypeLabel(FinkoAccountType.investment),
          accounts: _ofType(FinkoAccountType.investment),
          formatMoney: formatMoney,
          icon: Icons.trending_up,
        ),
        if (_ofType(FinkoAccountType.loan).isNotEmpty ||
            _ofType(FinkoAccountType.mortgage).isNotEmpty)
          _ExpandableTypeSection(
            title: otherLiabilitiesTitle,
            accounts: [
              ..._ofType(FinkoAccountType.loan),
              ..._ofType(FinkoAccountType.mortgage),
            ],
            formatMoney: formatMoney,
            icon: Icons.receipt_long_outlined,
          ),
      ],
    );
  }

  String _mainCurrency(List<FinkoAccount> list) {
    if (list.isEmpty) return 'MXN';
    return list.first.currency;
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
    required this.formatMoney,
    required this.icon,
  });

  final String title;
  final List<FinkoAccount> accounts;
  final String Function(int minor, String currencyCode) formatMoney;
  final IconData icon;

  @override
  State<_ExpandableTypeSection> createState() => _ExpandableTypeSectionState();
}

class _ExpandableTypeSectionState extends State<_ExpandableTypeSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.accounts.isEmpty) {
      return const SizedBox.shrink();
    }
    final sum = widget.accounts.fold<int>(
      0,
      (s, a) => s + (a.balanceMinorMain ?? a.balanceMinor),
    );
    final mainCur = widget.accounts.first.currency;
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
                widget.formatMoney(sum, mainCur),
                style: theme.textTheme.titleSmall,
              ),
              Icon(_open ? Icons.expand_less : Icons.expand_more),
            ],
          ),
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open)
          ...widget.accounts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(a.name),
                trailing: Text(widget.formatMoney(a.balanceMinor, a.currency)),
              ),
            ),
          ),
      ],
    );
  }
}
