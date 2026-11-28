import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/category_style.dart';
import 'package:flutter_application_1/widgets/confirm_delete_dialog.dart';
import 'package:flutter_application_1/widgets/solid_icon_badge.dart';

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
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.grey,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            _card(rows, context),
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
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? context.appColors.border
                : Colors.white,
            indent: 74,
            endIndent: 16,
          ),
        );
      }
      final bool isIncome = item['isIncome'];
      final bool isTransfer = item['isTransfer'] == true;

      final transactionId = item['transactionId'] as String;
      final row = InkWell(
        onTap: onTap == null ? null : () => onTap!(transactionId),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Builder(
                builder: (context) {
                  final category = item['category'] as String? ?? '';
                  final style = categoryStyle(category);
                  return SolidIconBadge(
                    size: 40,
                    icon: isTransfer
                        ? PhosphorIconsRegular.arrowsLeftRight
                        : style?.$1 ?? PhosphorIconsRegular.tag,
                    color: isTransfer
                        ? context.appColors.accent
                        : style?.$2 ??
                              (isIncome
                                  ? context.appColors.green
                                  : context.appColors.grey),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      grouped
                          ? item['categoryLabel'] as String? ?? 'Transaction'
                          : item['date'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.grey,
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
                        ? context.appColors.green
                        : context.appColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      rows.add(
        onDelete == null || isTransfer
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

  Widget _card(List<Widget> rows, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? context.appColors.border
            : Colors.white,
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
      color: context.appColors.danger,
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
