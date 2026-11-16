import 'package:flutter/material.dart';

import '../../core/category_style.dart';

class RecentTransactionWidget extends StatelessWidget {
  const RecentTransactionWidget({super.key, required this._transactions});

  final List<dynamic> _transactions;

  @override
  Widget build(BuildContext context) {
    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 44, color: Colors.grey),
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

    final rows = <Widget>[];
    for (var i = 0; i < _transactions.length; i++) {
      final item = _transactions[i] as Map<String, dynamic>;
      final bool isIncome = item['isIncome'];
      final category = (item['category'] as String?) ?? '';
      final style = categoryStyle(category);
      final icon =
          style?.$1 ??
          (isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded);
      final color =
          style?.$2 ??
          (isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626));

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 14),
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
                      item['date'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF87879D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item['amount'],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isIncome
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFFB9BDD0),
              ),
            ],
          ),
        ),
      );
      if (i < _transactions.length - 1) {
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
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
