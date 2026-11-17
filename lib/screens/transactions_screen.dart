import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: const Color(0xFF3B62FF).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Full transaction list coming soon',
              style: TextStyle(fontSize: 14, color: Color(0xFF87879D)),
            ),
          ],
        ),
      ),
    );
  }
}
