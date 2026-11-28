import 'package:flutter/material.dart';

import 'package:flutter_application_1/widgets/recent_transaction.dart';
import 'package:flutter_application_1/core/app_theme.dart';

class HomeTransactionSection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onDelete;

  const HomeTransactionSection({
    super.key,
    required this.transactions,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Transaction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.appColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 16),
        RecentTransactionWidget(
          transactions: transactions,
          onTap: onTap,
          onDelete: onDelete,
          grouped: false,
        ),
      ],
    );
  }
}
