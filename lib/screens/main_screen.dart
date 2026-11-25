import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/network/server_error.dart';
import 'package:flutter_application_1/feat/app_version/app_version_service.dart';
import 'package:flutter_application_1/feat/notification/notification_service.dart';
import 'package:flutter_application_1/screens/app_update_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _profileKey = GlobalKey<ProfileScreenState>();
  final _savingsKey = GlobalKey<SavingsScreenState>();
  final _reportKey = GlobalKey<ReportScreenState>();
  final _cardsKey = GlobalKey<CardsScreenState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasUnread = false;
  bool _reloadingAll = false;
  final Set<String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _checkAppUpdate();
  }

  void _setServerError(String id, bool hasError) {
    final changed = hasError ? _serverErrors.add(id) : _serverErrors.remove(id);
    if (changed && mounted) setState(() {});
  }

  Future<void> _reloadAll() async {
    if (_reloadingAll) return;
    setState(() => _reloadingAll = true);
    try {
      await Future.wait([
        _homeKey.currentState?.reload() ?? Future<void>.value(),
        _transactionsKey.currentState?.reload() ?? Future<void>.value(),
        _budgetKey.currentState?.reload() ?? Future<void>.value(),
        _profileKey.currentState?.reload() ?? Future<void>.value(),
        _savingsKey.currentState?.reload() ?? Future<void>.value(),
        _reportKey.currentState?.reload() ?? Future<void>.value(),
        _cardsKey.currentState?.reload() ?? Future<void>.value(),
        _loadUnread(),
      ]);
    } finally {
      if (mounted) setState(() => _reloadingAll = false);
    }
  }

  void _openTools() => setState(() => _index = 4);

  Future<void> _loadUnread() async {
    try {
      final items = await NotificationService().list();
      if (!mounted) return;
      setState(() => _hasUnread = items.any((e) => e['readAt'] == null));
      _setServerError('notifications', false);
    } catch (e) {
      _setServerError('notifications', isServerConnectionError(e));
    }
  }

  Future<void> _checkAppUpdate() async {
    final info = await AppVersionService().check();
    if (!mounted || info == null) return;
    if (info.status == AppUpdateStatus.required) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppUpdateScreen(
            currentVersion: info.currentVersion,
            latestVersion: info.latestVersion,
            updateUrl: info.updateUrl,
            releaseNotes: info.releaseNotes,
          ),
        ),
      );
      return;
    }
    if (info.status == AppUpdateStatus.optional) {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString('dismissed_update_version');
      if (dismissed == info.latestVersion || !mounted) return;
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update available'),
          content: Text(
            'A new version of DompetIQ (${info.latestVersion}) is available. You are currently using version ${info.currentVersion}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      if (shouldUpdate == true) {
        final uri = Uri.tryParse(info.updateUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        await prefs.setString('dismissed_update_version', info.latestVersion);
      }
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
        onServerError: (v) => _setServerError('home', v),
      ),
      TransactionsScreen(
        key: _transactionsKey,
        onChanged: (_) => _reloadAll(),
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
        onServerError: (v) => _setServerError('transactions', v),
      ),
      BudgetScreen(
        key: _budgetKey,
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
        onServerError: (v) => _setServerError('budget', v),
      ),
      ProfileScreen(
        key: _profileKey,
        onDataReset: _reloadAll,
        onServerError: (v) => _setServerError('profile', v),
      ),
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
        key: _savingsKey,
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
        onServerError: (v) => _setServerError('savings', v),
      ),
      ReportScreen(
        key: _reportKey,
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
        onServerError: (v) => _setServerError('report', v),
      ),
      CardsScreen(
        key: _cardsKey,
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifications: _openNotifications,
        hasUnreadNotifications: _hasUnread,
        onServerError: (v) => _setServerError('cards', v),
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
        body: Stack(
          children: [
            IndexedStack(index: _index, children: pages),
            if (_serverErrors.isNotEmpty)
              Positioned.fill(child: _buildServerError()),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildServerError() {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.warningCircle,
                    size: 44,
                    color: Color(0xFF3B62FF),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  "Can't reach the server",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "We couldn't connect right now. This may be caused by your internet connection or a temporary server issue. Please try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _reloadingAll ? null : _reloadAll,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B62FF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFB8C7FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _reloadingAll
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Try again',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      child: SizedBox(
        height: 50,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 44,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF3B62FF).withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                size: 26,
                color: active
                    ? const Color(0xFF3B62FF)
                    : const Color(0xFF9AA0AC),
              ),
            ),
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
