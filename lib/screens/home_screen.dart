import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/device_id.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/change_pin_screen.dart';
import 'package:flutter_application_1/widgets/recent_transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AuthService().logout(deviceId: await DeviceId.get());
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // saldo: GET /account-transfers, transaksi: GET /financial-record
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
    } on DioException catch (e) {
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
            // konten di bawah digeser -80 supaya kartu aksi overlap ke header
            Transform.translate(
              offset: const Offset(0, -80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionCard(),
                  const SizedBox(height: 24),
                  _buildTransactionSection(),
                  const SizedBox(height: 24),
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
                  IconButton(
                    onPressed: () => _showSnack('Menu coming soon'),
                    icon: const Icon(Icons.menu, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Color(0xFF87879D),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Search "Payments"',
                            style: TextStyle(
                              color: Color(0xFF87879D),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // settings: menyimpan Sign out karena mockup tidak punya slot logout
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'changePin') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePinScreen(),
                          ),
                        );
                      } else if (value == 'logout') {
                        _handleLogout();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'changePin',
                        child: Text('Change PIN'),
                      ),
                      PopupMenuItem(value: 'logout', child: Text('Sign out')),
                    ],
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                '🇮🇩 IDR',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(_balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Available Balance',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: () => _showSnack('Coming soon'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_card_rounded,
                          color: Color(0xFF3B62FF),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Money',
                          style: TextStyle(
                            color: Color(0xFF3B62FF),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ruang untuk kartu aksi yang overlap ke bawah
              // (112 - 80 = 32px jarak antara tombol Add Money dan kartu)
              const SizedBox(height: 112),
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
              onTap: () => _showSnack('Income form coming soon'),
            ),
            _verticalDivider(),
            _HeaderAction(
              icon: Icons.trending_down_rounded,
              label: 'Spending',
              color: const Color(0xFFDC2626),
              onTap: () => _showSnack('Spending form coming soon'),
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
