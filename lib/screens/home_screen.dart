import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/add_transaction_screen.dart';
import 'package:flutter_application_1/widgets/recent_transaction.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenProfile;

  const HomeScreen({super.key, this.onOpenMenu, this.onOpenProfile});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _balance = 0;
  int _income = 0;
  int _spending = 0;
  List<Map<String, dynamic>> _transactions = [];
  String? _avatar;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final data = await UserService.me();
      if (!mounted) return;
      setState(() {
        _avatar = StorageConfig.avatarUrl(data['avatar'] as String?);
      });
    } on DioException {
      return;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadSummary() async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    try {
      final response = await DioClient.instance.get(
        ApiRouteConfig.monthlySummary,
        queryParameters: {'month': month},
      );
      final current = response.data['data']['current'];
      if (!mounted) return;
      setState(() {
        _income = current['income'] as int;
        _spending = current['spending'] as int;
      });
    } on DioException {
      return;
    }
  }

  void reload() => _loadData();

  Future<void> _openTransactionForm(String type) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(initialType: type),
      ),
    );
    if (saved == true && mounted) _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        DioClient.instance.get(ApiRouteConfig.accountTransfers),
        DioClient.instance.get(
          ApiRouteConfig.financialRecord,
          queryParameters: {'pageSize': 10},
        ),
      ]);
      final accounts = (results[0].data['data']['accounts'] as List)
          .cast<Map<String, dynamic>>();

      setState(() {
        _balance = accounts.fold(0, (sum, a) => sum + (a['balance'] as int));
        _transactions = (results[1].data['data'] as List)
            .cast<Map<String, dynamic>>()
            .map((r) {
              final isIncome = r['type'] == 'Income';
              final category = r['categoryUser']?['category']?['name'] ?? '';
              final note = (r['note'] as String?) ?? '';
              return {
                'title': note.isNotEmpty
                    ? note
                    : category
                          .toLowerCase()
                          .replaceAll('_', ' ')
                          .replaceFirstMapped(
                            RegExp(r'^[a-z]'),
                            (m) => m[0]!.toUpperCase(),
                          ),
                'date': formatDateShort(DateTime.parse(r['transactionDate'])),
                'amount':
                    '${isIncome ? '+' : '-'} ${formatRupiah(r['amount'] as int)}',
                'isIncome': isIncome,
                'category': category,
              };
            })
            .toList();
        _isLoading = false;
      });
      _loadSummary();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return;
      }
      setState(() {
        _error =
            e.response?.data?['error']?['message'] ?? 'Failed to load data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F4F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F4F9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Transform.translate(
              offset: const Offset(0, -80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionCard(),
                  const SizedBox(height: 32),
                  _buildTransactionSection(),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B62FF), Color(0xFF2242D6)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.onOpenMenu,
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'DompetIQ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: widget.onOpenProfile,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: Colors.white,
                            backgroundImage: _avatar != null
                                ? NetworkImage(_avatar!)
                                : null,
                            child: _avatar == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF3B62FF),
                                    size: 22,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            top: 2,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                '🇮🇩 IDR',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: BalanceVisibility.toggle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: BalanceVisibility.visible,
                          builder: (context, visible, _) => Text(
                            visible ? formatRupiah(_balance) : '••••••',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<bool>(
                      valueListenable: BalanceVisibility.visible,
                      builder: (context, visible, _) => IconButton(
                        onPressed: BalanceVisibility.toggle,
                        icon: Icon(
                          visible
                              ? Icons.lock_open_rounded
                              : Icons.lock_rounded,
                        ),
                        iconSize: 20,
                        color: Colors.white70,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: visible ? 'Hide balance' : 'Show balance',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<bool>(
                valueListenable: BalanceVisibility.visible,
                builder: (context, visible, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SummaryItem(
                      label: 'Income',
                      amount: visible ? formatRupiah(_income) : '••••••',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      color: Colors.white24,
                    ),
                    _SummaryItem(
                      label: 'Spending',
                      amount: visible ? formatRupiah(_spending) : '••••••',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 108),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _HeaderAction(
              icon: Icons.trending_up_rounded,
              label: 'Income',
              color: const Color(0xFF16A34A),
              onTap: () => _openTransactionForm('Income'),
            ),
            _verticalDivider(),
            _HeaderAction(
              icon: Icons.trending_down_rounded,
              label: 'Spending',
              color: const Color(0xFFDC2626),
              onTap: () => _openTransactionForm('Spending'),
            ),
            _verticalDivider(),
            _HeaderAction(
              icon: Icons.swap_horiz_rounded,
              label: 'Transfer',
              color: const Color(0xFF3B62FF),
              onTap: () => _showSnack('Transfer form coming soon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 40, color: const Color(0xFFEDEEF3));
  }

  Widget _buildTransactionSection() {
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
        RecentTransactionWidget(transactions: _transactions),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;

  const _SummaryItem({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
