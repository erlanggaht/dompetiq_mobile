import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/add_transaction_screen.dart';
import 'package:flutter_application_1/screens/budget_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/screens/transactions_screen.dart';
import 'package:flutter_application_1/widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _homeKey = GlobalKey<HomeScreenState>();
  final _transactionsKey = GlobalKey<TransactionsScreenState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _pages = [
    HomeScreen(
      key: _homeKey,
      onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
      onOpenProfile: () => _onSlotTap(4),
      onTransactionSaved: () => _transactionsKey.currentState?.reload(),
    ),
    TransactionsScreen(
      key: _transactionsKey,
      onChanged: (_) => _homeKey.currentState?.reload(),
      onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
      onOpenProfile: () => _onSlotTap(4),
    ),
    const BudgetScreen(),
    const ProfileScreen(),
  ];

  int _index = 0;

  Future<void> _onSlotTap(int slot) async {
    if (slot == 2) {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
      );
      if (saved == true) {
        _homeKey.currentState?.reload();
        _transactionsKey.currentState?.reload();
      }
      return;
    }
    setState(() => _index = slot < 2 ? slot : slot - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: const AppDrawer(),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavSlot(
            icon: _index == 0 ? Icons.home_rounded : Icons.home_outlined,
            active: _index == 0,
            onTap: () => _onSlotTap(0),
          ),
          _NavSlot(
            key: const ValueKey('tab-transactions'),
            icon: _index == 1
                ? Icons.receipt_long_rounded
                : Icons.receipt_long_outlined,
            active: _index == 1,
            onTap: () => _onSlotTap(1),
          ),
          _AddButton(onTap: () => _onSlotTap(2)),
          _NavSlot(
            icon: _index == 2
                ? Icons.pie_chart_rounded
                : Icons.pie_chart_outline_rounded,
            active: _index == 2,
            onTap: () => _onSlotTap(3),
          ),
          _NavSlot(
            icon: _index == 3
                ? Icons.person_rounded
                : Icons.person_outline_rounded,
            active: _index == 3,
            onTap: () => _onSlotTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavSlot({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Icon(
            icon,
            size: 26,
            color: active ? const Color(0xFF1C1C1C) : const Color(0xFF9AA0AC),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        heightFactor: 1,
        child: Material(
          color: const Color(0xFF3B62FF),
          elevation: 6,
          shadowColor: const Color(0xFF3B62FF).withValues(alpha: 0.4),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 50,
              height: 50,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
