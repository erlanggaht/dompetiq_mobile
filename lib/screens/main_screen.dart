import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/feat/notification/notification_service.dart';
import 'package:flutter_application_1/screens/add_transaction_screen.dart';
import 'package:flutter_application_1/screens/budget_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/notifications_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/screens/report_screen.dart';
import 'package:flutter_application_1/screens/savings_screen.dart';
import 'package:flutter_application_1/screens/transactions_screen.dart';
import 'package:flutter_application_1/screens/tools_screen.dart';
import 'package:flutter_application_1/screens/cards_screen.dart';
import 'package:flutter_application_1/widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _homeKey = GlobalKey<HomeScreenState>();
  final _transactionsKey = GlobalKey<TransactionsScreenState>();
  final _budgetKey = GlobalKey<BudgetScreenState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  void _reloadAll() {
    _homeKey.currentState?.reload();
    _transactionsKey.currentState?.reload();
    _budgetKey.currentState?.reload();
  }

  void _openTools() => setState(() => _index = 4);

  Future<void> _loadUnread() async {
    try {
      final items = await NotificationService().list();
      if (!mounted) return;
      setState(() => _hasUnread = items.any((e) => e['readAt'] == null));
    } catch (_) {
      return;
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _loadUnread();
  }

  int _index = 0;

  Future<void> _onSlotTap(int slot) async {
    if (slot == 2) {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
      );
      if (saved == true) _reloadAll();
      return;
    }
    setState(() => _index = slot < 2 ? slot : slot - 1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        key: _homeKey,
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        onTransactionSaved: _reloadAll,
        onOpenTools: _openTools,
        hasUnreadNotifications: _hasUnread,
      ),
      TransactionsScreen(
        key: _transactionsKey,
        onChanged: (_) => _reloadAll(),
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
      ),
      BudgetScreen(
        key: _budgetKey,
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
      ),
      ProfileScreen(onDataReset: _reloadAll),
      ToolsScreen(
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
        onOpenTransactions: () => setState(() => _index = 1),
        onOpenBudget: () => setState(() => _index = 2),
        onOpenSavings: () => setState(() => _index = 5),
        onOpenReport: () => setState(() => _index = 6),
        onOpenCards: () => setState(() => _index = 7),
      ),
      SavingsScreen(
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
      ),
      ReportScreen(
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
      ),
      CardsScreen(
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
      ),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        backgroundColor: Colors.transparent,
        drawer: AppDrawer(
          onDataReset: _reloadAll,
          onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
          onOpenNotifications: _openNotifications,
          hasUnreadNotifications: _hasUnread,
          onOpenTools: _openTools,
          onOpenCards: () => setState(() => _index = 7),
        ),
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: _buildBottomBar(),
      ),
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
            icon: _index == 0
                ? PhosphorIconsBold.house
                : PhosphorIconsRegular.house,
            active: _index == 0,
            onTap: () => _onSlotTap(0),
          ),
          _NavSlot(
            key: const ValueKey('tab-transactions'),
            icon: _index == 1
                ? PhosphorIconsBold.receipt
                : PhosphorIconsRegular.receipt,
            active: _index == 1,
            onTap: () => _onSlotTap(1),
          ),
          _AddButton(onTap: () => _onSlotTap(2)),
          _NavSlot(
            icon: _index == 2
                ? PhosphorIconsBold.chartPie
                : PhosphorIconsRegular.chartPie,
            active: _index == 2,
            onTap: () => _onSlotTap(3),
          ),
          _NavSlot(
            icon: _index == 3
                ? PhosphorIconsBold.user
                : PhosphorIconsRegular.user,
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
              child: Icon(
                PhosphorIconsRegular.plus,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
