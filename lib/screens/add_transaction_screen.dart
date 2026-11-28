import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/category_style.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/feat/transaction/transaction_service.dart';
import 'package:flutter_application_1/widgets/amount_field.dart';

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
  bool _showAmountPad = !kIsWeb;
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
    _amountController.addListener(_onAmountChanged);
    _load();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
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

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  void _setQuickAmount(int amount) {
    _setAmountText(amount);
    _amountFocus.requestFocus();
  }

  void _setAmountText(int amount) {
    final text = formatThousands(amount);
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _appendAmountDigit(String digit) {
    final current = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final next = current == '0' ? digit : '$current$digit';
    final amount = int.tryParse(next);
    if (amount == null || amount > _maxAmount) return;
    _setAmountText(amount);
  }

  void _removeAmountDigit() {
    final current = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final next = current.length <= 1
        ? '0'
        : current.substring(0, current.length - 1);
    _setAmountText(int.parse(next));
  }

  void _closeAmountPad() {
    setState(() => _showAmountPad = false);
    _amountFocus.unfocus();
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Select account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.ink,
                ),
              ),
            ),
            for (final account in _rekenings)
              ListTile(
                title: Text(account['name'] as String),
                trailing: _rekeningUserId == account['rekeningUserId']
                    ? Icon(
                        PhosphorIconsRegular.check,
                        color: context.appColors.accent,
                      )
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            if (_showAmountPad && !_isLoading && _error == null)
              AmountKeypad(
                onDigit: _appendAmountDigit,
                onBackspace: _removeAmountDigit,
                onQuickAmount: _setQuickAmount,
                onDone: _closeAmountPad,
              ),
          ],
        ),
      ),
      bottomNavigationBar: _error != null || (_showAmountPad && !_isLoading)
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
                      backgroundColor: context.appColors.accent,
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
                            style: TextStyle(
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
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  PhosphorIconsRegular.arrowLeft,
                  color: context.appColors.ink,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.transaction != null
                  ? 'Edit Transaction'
                  : 'Add Transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.appColors.ink,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.appColors.border.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _typeTab('Income', 'Income', context.appColors.green),
              _typeTab('Spending', 'Spending', context.appColors.danger),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Amount',
          style: TextStyle(
            fontSize: 13,
            color: context.appColors.grey,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 8, top: 6),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.grey,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _amountController,
                focusNode: _amountFocus,
                showCursor: !kIsWeb,
                readOnly: !kIsWeb,
                keyboardType: kIsWeb
                    ? TextInputType.number
                    : TextInputType.none,
                textInputAction: kIsWeb
                    ? TextInputAction.next
                    : TextInputAction.none,
                onTap: kIsWeb
                    ? null
                    : () {
                        setState(() => _showAmountPad = true);
                        _amountFocus.requestFocus();
                      },
                onSubmitted: kIsWeb ? (_) => _noteFocus.requestFocus() : null,
                inputFormatters: [ThousandsFormatter()],
                cursorColor: context.appColors.accent,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.ink,
                  letterSpacing: -1,
                  height: 1.15,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (kIsWeb) _QuickAmountRow(onQuickAmount: _setQuickAmount),
        if (kIsWeb) const SizedBox(height: 20),
        Divider(height: 1, color: context.appColors.border),
        const SizedBox(height: 22),
        Text(
          'Category',
          style: TextStyle(
            fontSize: 13,
            color: context.appColors.grey,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 14),
        if (categories.isEmpty)
          Text(
            'No category available',
            style: TextStyle(color: context.appColors.grey),
          )
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
        Divider(height: 1, color: context.appColors.border),
        _metaRow('Account', _accountName, _pickAccount),
        Divider(height: 1, color: context.appColors.border),
        _metaRow('Date', formatDateShort(_date), _pickDate),
        Divider(height: 1, color: context.appColors.border),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  'Note',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: context.appColors.grey,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  focusNode: _noteFocus,
                  onTap: () => setState(() => _showAmountPad = false),
                  maxLength: 255,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _noteFocus.unfocus(),
                  onEditingComplete: _noteFocus.unfocus,
                  cursorColor: context.appColors.accent,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.ink,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    hintText: 'Add a note',
                    hintStyle: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.appColors.border),
      ],
    );
  }

  Widget _typeTab(String label, String value, Color color) {
    final selected = _type == value;
    final icon = value == 'Income'
        ? PhosphorIconsRegular.trendUp
        : PhosphorIconsRegular.trendDown;
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
              Icon(
                icon,
                size: 16,
                color: selected ? color : context.appColors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : context.appColors.grey,
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
    final icon = categoryStyle(name)?.$1 ?? PhosphorIconsRegular.tag;

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
              color: selected
                  ? context.appColors.accent
                  : context.appColors.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 21,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : context.appColors.grey,
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
              color: selected ? context.appColors.ink : context.appColors.grey,
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
                style: TextStyle(fontSize: 14.5, color: context.appColors.grey),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.ink,
                ),
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 20,
              color: context.appColors.border,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAmountRow extends StatelessWidget {
  final ValueChanged<int> onQuickAmount;

  const _QuickAmountRow({required this.onQuickAmount});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final amount in [50000, 100000, 500000, 1000000])
          ActionChip(
            label: Text('Rp ${formatThousands(amount)}'),
            onPressed: () => onQuickAmount(amount),
          ),
      ],
    );
  }
}
