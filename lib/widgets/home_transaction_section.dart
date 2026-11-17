import 'package:flutter/material.dart';

import 'package:flutter_application_1/widgets/recent_transaction.dart';

class HomeTransactionSection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const HomeTransactionSection({super.key, required this.transactions});

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
                Icons.arrow_forward_rounded,
                size: 22,
                color: Color(0xFF1C1C1C),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RecentTransactionWidget(transactions: transactions),
      ],
    );
  }
}
