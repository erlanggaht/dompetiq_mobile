import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/core/category_style.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/feat/transaction/transaction_service.dart';

const _accent = Color(0xFF3B62FF);
const _income = Color(0xFF16A34A);
const _spending = Color(0xFFDC2626);
const _ink = Color(0xFF111827);
const _muted = Color(0xFF8A90A2);
const _hairline = Color(0xFFEFF1F5);
const _maxAmount = 2147483647;

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  final Map<String, dynamic>? transaction;

  const AddTransactionScreen({
    super.key,
    this.initialType = 'Income',
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _service = TransactionService();
  final _amountController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  final _amountFocus = FocusNode();
  final _noteFocus = FocusNode();

  String _type = 'Income';
  int? _categoryId;
  int? _rekeningUserId;
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _rekenings = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final tx = widget.transaction;
    if (tx != null) {
      _type = (tx['type'] as String?) ?? widget.initialType;
      _amountController.text = formatThousands((tx['amount'] as num).toInt());
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
      _descriptionController.text = (tx['note'] as String?) ?? '';
      _categoryId = tx['categoryUser']?['category']?['id'] as int?;
      _rekeningUserId = tx['rekeningUserId'] as int?;
      final raw = tx['transactionDate'] as String?;
      if (raw != null) {
        _date = DateTime.parse(raw).toUtc().add(const Duration(hours: 7));
      }
    }
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _service.categories();
      final accounts = await _service.rekenings();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _rekenings = accounts;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _amountFocus.requestFocus(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String get _dateText {
    final m = _date.month.toString().padLeft(2, '0');
    final d = _date.day.toString().padLeft(2, '0');
    return '$m-$d-${_date.year}';
  }

  String get _accountName {
    final id = _rekeningUserId;
    if (id == null) return 'Select account';
    final match = _rekenings.where((r) => r['rekeningUserId'] == id);
    return match.isEmpty ? 'Select account' : match.first['name'] as String;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAccount() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Select account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            for (final account in _rekenings)
              ListTile(
                title: Text(account['name'] as String),
                trailing: _rekeningUserId == account['rekeningUserId']
                    ? const Icon(Icons.check_rounded, color: _accent)
                    : null,
                onTap: () =>
                    Navigator.pop(context, account['rekeningUserId'] as int),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _rekeningUserId = picked);
  }

  Future<void> _save() async {
    final amount =
        int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    final description = _descriptionController.text.trim();

    if (amount <= 0) {
      _showSnack('Amount must be greater than 0');
      return;
    }
    if (amount > _maxAmount) {
      _showSnack('Amount must be at most 2,147,483,647');
      return;
    }
    if (_categoryId == null) {
      _showSnack('Select a category');
      return;
    }
    if (_rekeningUserId == null) {
      _showSnack('Select an account');
      return;
    }
    if (description.length < 3) {
      _showSnack('Description must be at least 3 characters');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final transactionId = widget.transaction?['transactionId'] as String?;
      if (transactionId == null) {
        await _service.create(
          type: _type,
          amount: amount,
          categoryId: _categoryId!,
          rekeningUserId: _rekeningUserId!,
          transactionDate: _dateText,
          description: description,
        );
      } else {
        await _service.update(
          transactionId: transactionId,
          type: _type,
          amount: amount,
          categoryId: _categoryId!,
          rekeningUserId: _rekeningUserId!,
          transactionDate: _dateText,
          description: description,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: (_isLoading || _isSaving) ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.transaction != null
                                ? 'Save Changes'
                                : _type == 'Income'
                                ? 'Add Income'
                                : 'Add Spending',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
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

    final categories = _categories.where((c) => c['type'] == _type).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.transaction != null
                  ? 'Edit Transaction'
                  : 'Add Transaction',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _typeTab('Income', 'Income', _income),
              _typeTab('Spending', 'Spending', _spending),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Amount',
          style: TextStyle(fontSize: 13, color: _muted, letterSpacing: 0.2),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 6),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _amountController,
                focusNode: _amountFocus,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _noteFocus.requestFocus(),
                inputFormatters: [_ThousandsFormatter()],
                cursorColor: _accent,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -1,
                  height: 1.15,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: _hairline),
        const SizedBox(height: 22),
        const Text(
          'Category',
          style: TextStyle(fontSize: 13, color: _muted, letterSpacing: 0.2),
        ),
        const SizedBox(height: 14),
        if (categories.isEmpty)
          const Text('No category available', style: TextStyle(color: _muted))
        else
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 6,
            childAspectRatio: 0.82,
            children: categories.map(_categoryTile).toList(),
          ),
        const SizedBox(height: 18),
        const Divider(height: 1, color: _hairline),
        _metaRow('Account', _accountName, _pickAccount),
        const Divider(height: 1, color: _hairline),
        _metaRow('Date', formatDateShort(_date), _pickDate),
        const Divider(height: 1, color: _hairline),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const SizedBox(
                width: 92,
                child: Text(
                  'Note',
                  style: TextStyle(fontSize: 14.5, color: _muted),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  focusNode: _noteFocus,
                  maxLength: 255,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  cursorColor: _accent,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    hintText: 'Add a note',
                    hintStyle: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _hairline),
      ],
    );
  }

  Widget _typeTab(String label, String value, Color color) {
    final selected = _type == value;
    final icon = value == 'Income'
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = value;
          _categoryId = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.20)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? color : _muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryTile(Map<String, dynamic> category) {
    final id = category['id'] as int;
    final name = category['name'] as String;
    final selected = _categoryId == id;
    final icon = categoryStyle(name)?.$1 ?? Icons.label_outline;

    return GestureDetector(
      onTap: () => setState(() => _categoryId = id),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? _accent : const Color(0xFFF2F4F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 21,
              color: selected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _ink : _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 17),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: const TextStyle(fontSize: 14.5, color: _muted),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFC3C8D6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    if (digits.length > 15) return oldValue;
    final formatted = formatThousands(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
