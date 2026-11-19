import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/category_style.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/feat/transaction/transaction_service.dart';
import 'package:flutter_application_1/screens/add_transaction_screen.dart';
import 'package:flutter_application_1/widgets/confirm_delete_dialog.dart';

const _accent = Color(0xFF3B62FF);
const _income = Color(0xFF16A34A);
const _spending = Color(0xFFDC2626);
const _ink = Color(0xFF1C1C1C);
const _muted = Color(0xFF8A90A2);
const _hairline = Color(0xFFEFF1F5);
const _page = Color(0xFFF2F4F9);
const _wib = Duration(hours: 7);

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _service = TransactionService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _data == null;
      _error = null;
    });
    try {
      final data = await _service.getOne(widget.transactionId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool get _isIncome => _data!['type'] == 'Income';
  int get _amount => (_data!['amount'] as num).toInt();
  String get _note => (_data!['note'] as String?) ?? '';
  String get _category =>
      _data!['categoryUser']?['category']?['name'] as String? ?? '';
  String get _account =>
      _data!['rekeningUser']?['rekening']?['name'] as String? ?? '-';
  DateTime get _date =>
      DateTime.parse(_data!['transactionDate'] as String).toUtc().add(_wib);

  String get _categoryTitle {
    if (_category.isEmpty) return 'Transaction';
    return _category
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m[0]!.toUpperCase());
  }

  String get _title => _note.isNotEmpty ? _note : _categoryTitle;

  void _close() => Navigator.pop(context, _changed);

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          initialType: _data!['type'] as String,
          transaction: _data,
        ),
      ),
    );
    if (saved == true && mounted) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDeleteTransaction(context);
    if (!confirmed || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await _service.delete(widget.transactionId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: _page,
        body: SafeArea(child: _buildBody()),
        bottomNavigationBar: _data == null || _error != null
            ? null
            : _actions(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final color = _isIncome ? _income : _spending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _header(),
        const SizedBox(height: 20),
        _heroCard(color),
        const SizedBox(height: 14),
        _detailsCard(),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        InkWell(
          onTap: _close,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _hairline),
            ),
            child: const Icon(
              PhosphorIconsRegular.arrowLeft,
              color: _ink,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Transaction Detail',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _heroCard(Color color) {
    final style = categoryStyle(_category);
    final icon =
        style?.$1 ??
        (_isIncome
            ? PhosphorIconsRegular.trendUp
            : PhosphorIconsRegular.trendDown);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatDateShort(_date),
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _hairline),
          const SizedBox(height: 16),
          Text(
            _isIncome ? 'Income' : 'Spending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          ValueListenableBuilder<bool>(
            valueListenable: BalanceVisibility.visible,
            builder: (context, visible, _) => Text(
              visible
                  ? '${_isIncome ? '+' : '-'} ${formatRupiah(_amount)}'
                  : '••••••',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.8,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairline),
      ),
      child: Column(
        children: [
          _row('Category', _categoryTitle),
          const Divider(height: 1, color: _hairline, indent: 18, endIndent: 18),
          _row('Account', _account),
          const Divider(height: 1, color: _hairline, indent: 18, endIndent: 18),
          _row('Transaction ID', widget.transactionId),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, color: _muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _spending,
                      side: const BorderSide(color: Color(0xFFF3C7C7)),
                      backgroundColor: const Color(0xFFFEF5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isBusy ? null : _edit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
