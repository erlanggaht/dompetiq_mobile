import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/network/server_error.dart';
import 'package:flutter_application_1/feat/budget/budget_service.dart';
import 'package:flutter_application_1/feat/card/card_service.dart';
import 'package:flutter_application_1/feat/savings/savings_service.dart';
import 'package:flutter_application_1/feat/transaction/transaction_mapper.dart';
import 'package:flutter_application_1/feat/transaction/transaction_service.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/add_transaction_screen.dart';
import 'package:flutter_application_1/screens/transaction_detail_screen.dart';
import 'package:flutter_application_1/widgets/home_action_card.dart';
import 'package:flutter_application_1/widgets/home_header.dart';
import 'package:flutter_application_1/widgets/home_progress_section.dart';
import 'package:flutter_application_1/widgets/home_transaction_section.dart';

const _wib = Duration(hours: 7);

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onTransactionSaved;
  final VoidCallback? onOpenTools;
  final bool hasUnreadNotifications;
  final ValueChanged<bool>? onServerError;

  const HomeScreen({
    super.key,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.onTransactionSaved,
    this.onOpenTools,
    this.hasUnreadNotifications = false,
    this.onServerError,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _balance = 0;
  int _income = 0;
  int _spending = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _savings = [];
  bool _isLoading = true;
  bool _hasLoaded = false;
  int _loadSeq = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadProfile();
    _loadBudgets();
    _loadCards();
    _loadSavings();
  }

  Future<void> _loadProfile({bool refresh = false}) async {
    try {
      final data = refresh
          ? await UserService.refresh()
          : await UserService.me();
      if (!mounted) return;
      await BalanceVisibility.useAccount(data['id']);
    } catch (_) {
      return;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteTransaction(String transactionId) async {
    if (transactionId.startsWith('ledger-')) return;
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

  Future<void> reload() async {
    await Future.wait([
      _loadData(),
      _loadProfile(refresh: true),
      _loadBudgets(),
      _loadCards(),
      _loadSavings(),
    ]);
  }

  Future<void> _loadBudgets() async {
    try {
      final budgets = await BudgetService().budgets();
      if (!mounted) return;
      setState(() => _budgets = budgets);
    } catch (_) {
      return;
    }
  }

  Future<void> _loadCards() async {
    try {
      final data = await CardService().load();
      final raw = data['cardInfomation'];
      final cards = raw is List
          ? raw.cast<Map<String, dynamic>>()
          : raw is Map
          ? [raw.cast<String, dynamic>()]
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => _cards = cards);
    } catch (_) {
      return;
    }
  }

  Future<void> _loadSavings() async {
    try {
      final data = await SavingsService().load();
      final goals = (data['goals'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _savings = goals);
    } catch (_) {
      return;
    }
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
    if (transactionId.startsWith('ledger-')) {
      final item = _transactions.firstWhere(
        (item) => item['transactionId'] == transactionId,
        orElse: () => <String, dynamic>{},
      );
      if (item.isEmpty || !mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(item['title'] as String? ?? 'Transfer ke Saving Goal'),
          content: Text(
            'Saving Goal: ${item['categoryLabel']}\n'
            'Nominal: ${item['amount']}\n'
            'Tanggal: ${item['date']}\n\n'
            'Transfer Saving Goal tidak dapat diedit atau dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }
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
        DioClient.instance.get(ApiRouteConfig.savingsGoalActivity),
      ]);
      if (!mounted || seq != _loadSeq) return;
      final accounts = (results[0].data['data']['accounts'] as List)
          .cast<Map<String, dynamic>>();
      final transactions =
          [
            ...(results[1].data['data'] as List).cast<Map<String, dynamic>>(),
            ...(results[2].data['data'] as List).cast<Map<String, dynamic>>(),
          ].map(mapTransaction).toList()..sort(
            (a, b) => (b['dateTime'] as DateTime).compareTo(
              a['dateTime'] as DateTime,
            ),
          );
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
      widget.onServerError?.call(false);
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
        e,
        e.response?.data?['error']?['message'] ?? 'Failed to load data',
      );
    } catch (e) {
      _onLoadFailed(seq, e, 'Failed to load data');
    }
  }

  void _onLoadFailed(int seq, Object error, String message) {
    if (!mounted || seq != _loadSeq) return;
    final serverError = isServerConnectionError(error);
    widget.onServerError?.call(serverError);
    if (_hasLoaded) {
      if (!serverError) _showSnack(message);
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
                balance: _balance,
                income: _income,
                spending: _spending,
                onOpenMenu: widget.onOpenMenu,
                onOpenNotifications: widget.onOpenNotifications,
                hasUnreadNotifications: widget.hasUnreadNotifications,
              ),
              Transform.translate(
                offset: const Offset(0, -80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeActionCard(
                      onIncome: () => _openTransactionForm('Income'),
                      onSpending: () => _openTransactionForm('Spending'),
                      onTools: widget.onOpenTools ?? () {},
                    ),
                    const SizedBox(height: 28),
                    HomeProgressSection(
                      budgets: _budgets,
                      cards: _cards,
                      savings: _savings,
                    ),
                    const SizedBox(height: 28),
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
