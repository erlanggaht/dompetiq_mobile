import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/widgets/confirm_delete_dialog.dart';

class RecentTransactionWidget extends StatelessWidget {
  const RecentTransactionWidget({
    super.key,
    required this._transactions,
    this.onTap,
    this.onDelete,
    this.grouped = true,
  });

  final List<dynamic> _transactions;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onDelete;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(PhosphorIconsRegular.receipt, size: 44, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No transactions yet',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final sections = <Widget>[];
    var rows = <Widget>[];
    String? group;

    void closeGroup() {
      if (rows.isEmpty) return;
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (group!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  group,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            _card(rows),
          ],
        ),
      );
      rows = <Widget>[];
    }

    for (var i = 0; i < _transactions.length; i++) {
      final item = _transactions[i] as Map<String, dynamic>;
      final label = grouped ? formatDayLabel(item['dateTime'] as DateTime) : '';
      if (label != group) {
        closeGroup();
        group = label;
      } else {
        rows.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF0F1F5),
            indent: 74,
            endIndent: 16,
          ),
        );
      }
      final bool isIncome = item['isIncome'];

      final transactionId = item['transactionId'] as String;
      final row = InkWell(
        onTap: onTap == null ? null : () => onTap!(transactionId),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      grouped
                          ? item['categoryLabel'] as String? ?? 'Transaction'
                          : item['date'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF87879D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<bool>(
                valueListenable: BalanceVisibility.visible,
                builder: (context, visible, _) => Text(
                  visible ? (item['amount'] as String) : '••••••',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isIncome
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      rows.add(
        onDelete == null
            ? row
            : Dismissible(
                key: ValueKey(transactionId),
                direction: DismissDirection.endToStart,
                background: const _DeleteBackground(),
                confirmDismiss: (_) => confirmDeleteTransaction(context),
                onDismissed: (_) => onDelete!(transactionId),
                child: row,
              ),
      );
    }

    closeGroup();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, section) in sections.indexed) ...[
          if (i > 0) const SizedBox(height: 18),
          section,
        ],
      ],
    );
  }

  Widget _card(List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: rows),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDC2626),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.trash, color: Colors.white, size: 20),
          SizedBox(width: 6),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
