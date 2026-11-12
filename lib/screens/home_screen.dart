import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/recent_transaction.dart';

import '../widgets/balance_card.dart';
import '../widgets/user_header_section.dart';

class HomeScreen extends StatelessWidget {
  final List _transactions = [
    {
      'title': 'Gaji Bulanan',
      'date': '10 Nov 2026',
      'amount': '+ Rp. 5.000.000',
      'isIncome': true,
    },
    {
      'title': 'Makan Siang',
      'date': '11 Nov 2026',
      'amount': '- Rp. 35.000',
      'isIncome': false,
    },
    {
      'title': 'Kopi Kenangan',
      'date': '11 Nov 2026',
      'amount': '- Rp. 22.000',
      'isIncome': false,
    },
  ];

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.blueAccent,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [UserHeaderSection(), const SizedBox(height: 16)],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 0.5],
                  colors: [Colors.blueAccent, Colors.white],
                ),
              ),
              child: BalanceCard(),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            RecentTransactionWidget(transactions: _transactions),
          ],
        ),
      ),
    );
  }
}
