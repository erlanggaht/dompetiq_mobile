import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/widgets/recent_transaction.dart';

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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Transaction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              Spacer(),
              Icon(
                PhosphorIconsRegular.arrowRight,
                size: 22,
                color: Color(0xFF1C1C1C),
              ),
            ],
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
