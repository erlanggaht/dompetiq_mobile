import 'package:flutter/material.dart';

// Halaman anggaran — belum dibangun.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Budget',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Budget management coming soon',
              style: TextStyle(fontSize: 14, color: Color(0xFF87879D)),
            ),
          ],
        ),
      ),
    );
  }
}
