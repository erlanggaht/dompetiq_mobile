import 'dart:async';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/network/server_error.dart';
import 'package:flutter_application_1/feat/transaction/transaction_mapper.dart';
import 'package:flutter_application_1/feat/transaction/transaction_service.dart';
import 'package:flutter_application_1/screens/transaction_detail_screen.dart';
import 'package:flutter_application_1/widgets/app_section_header.dart';
import 'package:flutter_application_1/widgets/app_bottom_nav.dart';
import 'package:flutter_application_1/widgets/recent_transaction.dart';

const _filters = ['All', 'Income', 'Spending'];
const _accent = Color(0xFF3B62FF);
const _ink = Color(0xFF1C1C1C);
const _muted = Color(0xFF8A90A2);
const _field = Color(0xFFF2F4F9);
const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
);

class TransactionsScreen extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final bool hasUnreadNotifications;
  final bool showBottomNav;
  final ValueChanged<bool>? onServerError;

  const TransactionsScreen({
    super.key,
    this.onChanged,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.hasUnreadNotifications = false,
    this.showBottomNav = false,
    this.onServerError,
  });

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  final _service = TransactionService();
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categories = [];
  String _filter = 'All';
  int? _rekeningUserId;
  int? _categoryId;
  DateTimeRange? _range;
  int _page = 1;
  int _total = 0;
  bool _isLoading = true;
  bool _hasLoaded = false;
  bool _loadingMore = false;
  String? _error;
  int _loadSeq = 0;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
    _loadOptions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> reload() => _load();

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _openDetail(String transactionId) async {
    if (transactionId.startsWith('ledger-')) {
      final item = _items.firstWhere(
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
      _load();
      widget.onChanged?.call(transactionId);
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    if (transactionId.startsWith('ledger-')) return;
    setState(
      () => _items.removeWhere((t) => t['transactionId'] == transactionId),
    );
    try {
      await _service.delete(transactionId);
      widget.onChanged?.call(transactionId);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      _load();
    }
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        _service.categories(),
        _service.rekenings(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _accounts = results[1];
      });
    } catch (_) {
      return;
    }
  }

  void _apply() {
    if (!mounted) return;
    setState(() => _hasLoaded = false);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _load();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _apply);
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    if (!_hasLoaded) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final page = await _service.records(
        type: _filter == 'All' ? null : _filter,
        search: _searchController.text.trim(),
        rekeningUserId: _rekeningUserId,
        categoryId: _categoryId,
        start: _range?.start,
        end: _range?.end,
      );
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _items = page.items.map(mapTransaction).toList();
        _total = page.total;
        _page = 1;
        _loadingMore = false;
        _hasLoaded = true;
        _isLoading = false;
        _error = null;
      });
      widget.onServerError?.call(false);
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      final serverError = isServerConnectionError(e);
      widget.onServerError?.call(serverError);
      if (_hasLoaded) {
        setState(() => _isLoading = false);
        if (!serverError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _isLoading || !_hasMore) return;
    final seq = _loadSeq;
    setState(() => _loadingMore = true);
    try {
      final page = await _service.records(
        page: _page + 1,
        type: _filter == 'All' ? null : _filter,
        search: _searchController.text.trim(),
        rekeningUserId: _rekeningUserId,
        categoryId: _categoryId,
        start: _range?.start,
        end: _range?.end,
      );
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _items = appendUnique(_items, page.items.map(mapTransaction).toList());
        _total = page.total;
        _page += 1;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _field,
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(onHome: () => Navigator.pop(context))
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'Transactions',
              onOpenMenu: widget.onOpenMenu,
              onOpenNotifications: widget.onOpenNotifications,
              hasUnreadNotifications: widget.hasUnreadNotifications,
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final filter in _filters) ...[
                        if (filter != _filters.first) const SizedBox(width: 8),
                        Expanded(child: _chip(filter)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _searchField()),
                      const SizedBox(width: 8),
                      _filterButton(),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final selected = _filter == label;
    final color = switch (label) {
      'Income' => const Color(0xFF16A34A),
      'Spending' => const Color(0xFFDC2626),
      _ => _accent,
    };
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (_filter == label) return;
          setState(() => _filter = label);
          _apply();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : _field,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : _muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      onSubmitted: (_) => _apply(),
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 13.5, color: _ink),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _field,
        hintText: 'Search note or amount',
        hintStyle: const TextStyle(fontSize: 13.5, color: _muted),
        prefixIcon: const Icon(
          PhosphorIconsRegular.magnifyingGlass,
          size: 19,
          color: _muted,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(
                  PhosphorIconsRegular.x,
                  size: 17,
                  color: _muted,
                ),
                onPressed: () {
                  _searchController.clear();
                  _apply();
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  int get _activeCount =>
      (_rekeningUserId == null ? 0 : 1) +
      (_categoryId == null ? 0 : 1) +
      (_range == null ? 0 : 1);

  Widget _filterButton() {
    final count = _activeCount;
    return InkWell(
      onTap: _openFilters,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _field,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Badge.count(
          count: count,
          isLabelVisible: count > 0,
          backgroundColor: _accent,
          child: Icon(
            PhosphorIconsRegular.slidersHorizontal,
            size: 20,
            color: count > 0 ? _accent : _muted,
          ),
        ),
      ),
    );
  }

  String get _accountName {
    if (_rekeningUserId == null) return 'All accounts';
    final match = _accounts.where(
      (r) => r['rekeningUserId'] == _rekeningUserId,
    );
    return match.isEmpty ? 'All accounts' : match.first['name'] as String;
  }

  String get _categoryName {
    if (_categoryId == null) return 'All categories';
    final match = _categories.where((c) => c['id'] == _categoryId);
    return match.isEmpty ? 'All categories' : match.first['name'] as String;
  }

  String get _rangeText {
    final range = _range;
    if (range == null) return 'All dates';
    return '${formatDateShort(range.start)} - ${formatDateShort(range.end)}';
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: _sheetShape,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          void changed() {
            setSheet(() {});
            _apply();
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _rekeningUserId = null;
                            _categoryId = null;
                            _range = null;
                          });
                          changed();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                _filterTile('Account', _accountName, () async {
                  final picked = await _pickAccount();
                  if (picked == null) return;
                  setState(() => _rekeningUserId = picked == 0 ? null : picked);
                  changed();
                }),
                _filterTile('Category', _categoryName, () async {
                  final picked = await _pickCategory();
                  if (picked == null) return;
                  setState(() => _categoryId = picked == 0 ? null : picked);
                  changed();
                }),
                _filterTile('Date', _rangeText, () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDateRange: _range,
                  );
                  if (picked == null) return;
                  setState(() => _range = picked);
                  changed();
                }),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterTile(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: _muted),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              size: 20,
              color: _muted,
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _pickAccount() async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: _sheetShape,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _pickerTitle('Account'),
            _pickerTile('All accounts', _rekeningUserId == null, 0),
            for (final account in _accounts)
              _pickerTile(
                account['name'] as String,
                _rekeningUserId == account['rekeningUserId'],
                account['rekeningUserId'] as int,
              ),
          ],
        ),
      ),
    );
  }

  Future<int?> _pickCategory() async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: _sheetShape,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _pickerTitle('Category'),
            _pickerTile('All categories', _categoryId == null, 0),
            for (final category in _categories)
              _pickerTile(
                category['name'] as String,
                _categoryId == category['id'],
                category['id'] as int,
              ),
          ],
        ),
      ),
    );
  }

  Widget _pickerTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      ),
    );
  }

  Widget _pickerTile(String title, bool selected, int value) {
    return ListTile(
      title: Text(title),
      trailing: selected
          ? const Icon(PhosphorIconsRegular.check, color: _accent)
          : null,
      onTap: () => Navigator.pop(context, value),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          RecentTransactionWidget(
            transactions: _items,
            onTap: _openDetail,
            onDelete: _deleteTransaction,
          ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
