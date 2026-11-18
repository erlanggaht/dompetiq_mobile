import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/feat/transaction/transaction_mapper.dart';
import 'package:flutter_application_1/feat/transaction/transaction_service.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/add_transaction_screen.dart';
import 'package:flutter_application_1/screens/transaction_detail_screen.dart';
import 'package:flutter_application_1/widgets/home_action_card.dart';
import 'package:flutter_application_1/widgets/home_header.dart';
import 'package:flutter_application_1/widgets/home_transaction_section.dart';

const _wib = Duration(hours: 7);

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onTransactionSaved;

  const HomeScreen({
    super.key,
    this.onOpenMenu,
    this.onOpenProfile,
    this.onTransactionSaved,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _balance = 0;
  int _income = 0;
  int _spending = 0;
  List<Map<String, dynamic>> _transactions = [];
  String? _avatar;
  String _name = '';
  bool _isLoading = true;
  bool _hasLoaded = false;
  int _loadSeq = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAvatar();
  }

  Future<void> _loadAvatar({bool refresh = false}) async {
    try {
      final data = refresh
          ? await UserService.refresh()
          : await UserService.me();
      if (!mounted) return;
      await BalanceVisibility.useAccount(data['id']);
      if (!mounted) return;
      setState(() {
        _avatar = StorageConfig.avatarUrl(data['avatar'] as String?);
        _name =
            (data['fullName'] as String?) ??
            (data['username'] as String? ?? '');
      });
    } catch (_) {
      return;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteTransaction(String transactionId) async {
    setState(
      () =>
          _transactions.removeWhere((t) => t['transactionId'] == transactionId),
    );
    try {
      await TransactionService().delete(transactionId);
      widget.onTransactionSaved?.call();
      _loadData();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
      _loadData();
    }
  }

  Future<void> _loadSummary(int seq) async {
    final now = DateTime.now().toUtc().add(_wib);
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    try {
      final response = await DioClient.instance.get(
        ApiRouteConfig.monthlySummary,
        queryParameters: {'month': month},
      );
      if (!mounted || seq != _loadSeq) return;
      final current = response.data['data']['current'];
      setState(() {
        _income = (current['income'] as num).toInt();
        _spending = (current['spending'] as num).toInt();
      });
    } catch (_) {
      return;
    }
  }

  void reload() {
    _loadData();
    _loadAvatar(refresh: true);
  }

  Future<void> _openTransactionForm(String type) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(initialType: type),
      ),
    );
    if (saved == true && mounted) {
      _loadData();
      widget.onTransactionSaved?.call();
    }
  }

  Future<void> _openDetail(String transactionId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailScreen(transactionId: transactionId),
      ),
    );
    if (changed == true && mounted) {
      _loadData();
      widget.onTransactionSaved?.call();
    }
  }

  Future<void> _loadData() async {
    final seq = ++_loadSeq;
    if (!_hasLoaded) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        DioClient.instance.get(ApiRouteConfig.accountTransfers),
        DioClient.instance.get(
          ApiRouteConfig.financialRecord,
          queryParameters: {'pageSize': 10},
        ),
      ]);
      if (!mounted || seq != _loadSeq) return;
      final accounts = (results[0].data['data']['accounts'] as List)
          .cast<Map<String, dynamic>>();
      final transactions = (results[1].data['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(mapTransaction)
          .toList();
      setState(() {
        _balance = accounts.fold(
          0,
          (sum, a) => sum + (a['balance'] as num).toInt(),
        );
        _transactions = transactions;
        _hasLoaded = true;
        _isLoading = false;
        _error = null;
      });
      await _loadSummary(seq);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/auth/login',
              (_) => false,
            );
          }
        });
        return;
      }
      _onLoadFailed(
        seq,
        e.response?.data?['error']?['message'] ?? 'Failed to load data',
      );
    } catch (_) {
      _onLoadFailed(seq, 'Failed to load data');
    }
  }

  void _onLoadFailed(int seq, String message) {
    if (!mounted || seq != _loadSeq) return;
    if (_hasLoaded) {
      _showSnack(message);
      return;
    }
    setState(() {
      _error = message;
      _isLoading = false;
    });
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(
                avatarUrl: _avatar,
                name: _name.isEmpty ? 'DompetIQ' : _name,
                balance: _balance,
                income: _income,
                spending: _spending,
                onOpenMenu: widget.onOpenMenu,
                onOpenProfile: widget.onOpenProfile,
              ),
              Transform.translate(
                offset: const Offset(0, -80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeActionCard(
                      onIncome: () => _openTransactionForm('Income'),
                      onSpending: () => _openTransactionForm('Spending'),
                      onTransfer: () => _showSnack('Transfer form coming soon'),
                    ),
                    const SizedBox(height: 32),
                    HomeTransactionSection(
                      transactions: _transactions,
                      onTap: _openDetail,
                      onDelete: _deleteTransaction,
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
