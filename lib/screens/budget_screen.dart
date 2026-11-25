import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/network/server_error.dart';
import 'package:flutter_application_1/feat/budget/budget_service.dart';
import 'package:flutter_application_1/feat/transaction/transaction_service.dart';
import 'package:flutter_application_1/widgets/amount_field.dart';
import 'package:flutter_application_1/widgets/app_section_header.dart';
import 'package:flutter_application_1/widgets/app_bottom_nav.dart';

class BudgetScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final bool hasUnreadNotifications;
  final bool showBottomNav;
  final ValueChanged<bool>? onServerError;

  const BudgetScreen({
    super.key,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.hasUnreadNotifications = false,
    this.showBottomNav = false,
    this.onServerError,
  });

  @override
  State<BudgetScreen> createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen> {
  final _service = BudgetService();
  List<_BudgetPeriod> _periods = [];
  List<Map<String, dynamic>> _categories = [];
  String _periodType = 'monthly';
  bool _loading = true;
  bool _hasData = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && !_hasData) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _service.budgets(),
        TransactionService().categories(),
      ]);
      if (!mounted) return;
      setState(() {
        _periods = results[0].map(_BudgetPeriod.fromJson).toList();
        _categories = results[1].where((c) => c['type'] == 'Spending').toList();
        _loading = false;
        _hasData = true;
        _error = null;
      });
      widget.onServerError?.call(false);
    } catch (e) {
      if (!mounted) return;
      final serverError = isServerConnectionError(e);
      widget.onServerError?.call(serverError);
      final message = e.toString().replaceFirst('Exception: ', '');
      if (_hasData) {
        setState(() => _loading = false);
        if (!serverError) _showMessage(message);
      } else {
        setState(() {
          _loading = false;
          _error = message;
        });
      }
    }
  }

  Future<void> reload() => _load(showLoading: false);

  // Latest period is not always the active one (weekly periods expire).
  _BudgetPeriod? get _current {
    final today = _dayOnly(DateTime.now());
    for (final period in _periods) {
      final start = period.startDate;
      final end = period.endDate;
      if (period.periodType != _periodType || start == null || end == null) {
        continue;
      }
      if (!today.isBefore(_dayOnly(start)) && !today.isAfter(_dayOnly(end))) {
        return period;
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(onHome: () => Navigator.pop(context))
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                AppSectionHeader(
                  title: 'Budget',
                  onOpenMenu: widget.onOpenMenu,
                  onOpenNotifications: widget.onOpenNotifications,
                  hasUnreadNotifications: widget.hasUnreadNotifications,
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          if (!_loading && _error == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 104,
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => _openEditor(null),
                  icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                  label: const Text('Add budget'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B62FF),
                    foregroundColor: Colors.white,
                    shadowColor: const Color(0xFF3B62FF).withValues(alpha: 0.3),
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final period = _current;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
        children: [
          _PeriodToggle(
            selected: _periodType,
            onChanged: (value) => setState(() => _periodType = value),
          ),
          const SizedBox(height: 18),
          _SummaryCard(period: period),
          const SizedBox(height: 24),
          if (period == null || period.items.isEmpty)
            _emptyState()
          else
            ...period.items.map(
              (item) => _BudgetCard(
                item: item,
                onEdit: () => _openEditor(item),
                onDelete: () => _delete(item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() => Container(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        Icon(
          PhosphorIconsRegular.chartPie,
          size: 44,
          color: const Color(0xFFB9BDD0),
        ),
        const SizedBox(height: 12),
        const Text(
          'No budget yet',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Add an allocation for a spending category',
          style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
        ),
      ],
    ),
  );

  Future<void> _openEditor(_BudgetItem? item) async {
    if (_categories.isEmpty) {
      _showMessage('No spending category available');
      return;
    }
    final usedIds = (_current?.items ?? [])
        .map((e) => e.categoryUserId)
        .toSet();
    final available = _categories.where((category) {
      final id = category['categoryUserId'] as int;
      return item == null ? !usedIds.contains(id) : id == item.categoryUserId;
    }).toList();
    if (available.isEmpty) {
      _showMessage(
        item == null
            ? 'All spending categories already have a budget'
            : 'Category is no longer available',
      );
      return;
    }

    int? categoryUserId = item?.categoryUserId;
    final amount = TextEditingController(
      text: item == null ? '' : formatThousands(item.allocated),
    );
    bool saving = false;
    final initialAmount = amount.text;
    final initialCategory = categoryUserId;
    bool isDirty() =>
        amount.text != initialAmount || categoryUserId != initialCategory;
    final keys = AmountKeys(amount);
    bool showKeypad = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => PopScope(
          canPop: !isDirty(),
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final discard = await showDialog<bool>(
              context: sheetContext,
              builder: (context) => AlertDialog(
                title: const Text('Discard changes?'),
                content: const Text(
                  'The budget you entered will not be saved.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep editing'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            );
            if (discard == true && sheetContext.mounted) {
              Navigator.pop(sheetContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item == null ? 'Add budget' : 'Edit budget',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item == null
                              ? 'Only categories without a budget are shown'
                              : 'Change the allocation for this category',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<int>(
                          initialValue: categoryUserId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final category in available)
                              DropdownMenuItem<int>(
                                value: category['categoryUserId'] as int,
                                child: Text(category['name'] as String),
                              ),
                          ],
                          onChanged: item == null
                              ? (value) =>
                                    setSheet(() => categoryUserId = value)
                              : null,
                        ),
                        const SizedBox(height: 14),
                        AmountField(
                          controller: amount,
                          label: 'Allocation',
                          useInternalKeypad: false,
                          onTap: () => setSheet(() => showKeypad = true),
                          onChanged: () => setSheet(() {}),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final digits = amount.text.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    );
                                    final allocated = int.tryParse(digits) ?? 0;
                                    if (categoryUserId == null ||
                                        allocated <= 0) {
                                      _showMessage(
                                        'Choose a category and enter an amount',
                                      );
                                      return;
                                    }
                                    setSheet(() => saving = true);
                                    try {
                                      if (item == null) {
                                        await _service.create(
                                          periodType: _periodType,
                                          categoryUserId: categoryUserId!,
                                          allocated: allocated,
                                        );
                                      } else {
                                        await _service.updateItem(
                                          item.id,
                                          allocated,
                                        );
                                      }
                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                      await _load(showLoading: false);
                                    } catch (e) {
                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                      _showMessage(
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      );
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF3B62FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showKeypad)
                AmountKeypad(
                  fullWidth: true,
                  onDigit: (digit) {
                    keys.append(digit);
                    setSheet(() {});
                  },
                  onBackspace: () {
                    keys.backspace();
                    setSheet(() {});
                  },
                  onQuickAmount: (value) {
                    keys.set(value);
                    setSheet(() {});
                  },
                  onDone: () => setSheet(() => showKeypad = false),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(_BudgetItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text('Remove the ${item.categoryName} allocation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD92D20),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteItem(item.id);
      await _load(showLoading: false);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class _BudgetPeriod {
  final int id;
  final String name;
  final String periodType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalAllocated;
  final int totalSpent;
  final List<_BudgetItem> items;

  _BudgetPeriod({
    required this.id,
    required this.name,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.totalAllocated,
    required this.totalSpent,
    required this.items,
  });

  factory _BudgetPeriod.fromJson(Map<String, dynamic> json) => _BudgetPeriod(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    periodType: json['periodType'] as String? ?? 'monthly',
    startDate: DateTime.tryParse(json['startDate'] as String? ?? '')?.toLocal(),
    endDate: DateTime.tryParse(json['endDate'] as String? ?? '')?.toLocal(),
    totalAllocated: (json['totalAllocated'] as num?)?.toInt() ?? 0,
    totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
    items: (json['items'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_BudgetItem.fromJson)
        .toList(),
  );
}

class _BudgetItem {
  final int id;
  final int categoryUserId;
  final int allocated;
  final int spent;
  final int remaining;
  final String categoryName;

  _BudgetItem({
    required this.id,
    required this.categoryUserId,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.categoryName,
  });

  factory _BudgetItem.fromJson(Map<String, dynamic> json) => _BudgetItem(
    id: (json['id'] as num).toInt(),
    categoryUserId: (json['categoryUserId'] as num?)?.toInt() ?? 0,
    allocated: (json['allocated'] as num?)?.toInt() ?? 0,
    spent: (json['spent'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
    categoryName: json['categoryName'] as String? ?? 'Category',
  );
}

class _PeriodToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _segment('Monthly', 'monthly'),
          _segment('Weekly', 'weekly'),
        ],
      ),
    );
  }

  Widget _segment(String label, String value) {
    final active = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF101828) : const Color(0xFF667085),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _BudgetPeriod? period;

  const _SummaryCard({required this.period});

  @override
  Widget build(BuildContext context) {
    final current = period;
    final allocated = current?.totalAllocated ?? 0;
    final spent = current?.totalSpent ?? 0;
    final remaining = allocated - spent;
    final ratio = allocated == 0 ? 0.0 : (spent / allocated).clamp(0.0, 1.0);
    final overCount = current?.items.where((i) => i.remaining < 0).length ?? 0;

    final range = current?.startDate != null && current?.endDate != null
        ? '${formatDateShort(current!.startDate!)} – ${formatDateShort(current.endDate!)}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (range != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              range,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B62FF), Color(0xFF2242D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                remaining < 0 ? 'Over budget' : 'Remaining',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                formatRupiah(remaining.abs()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent ${formatRupiah(spent)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'of ${formatRupiah(allocated)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              if (overCount > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '$overCount ${overCount == 1 ? 'category' : 'categories'} over budget',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final _BudgetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = item.allocated == 0
        ? 0.0
        : (item.spent / item.allocated).clamp(0.0, 1.0);
    final color = ratio >= 1
        ? const Color(0xFFDC2626)
        : ratio >= 0.7
        ? const Color(0xFFF59E0B)
        : const Color(0xFF3B62FF);
    final over = item.remaining < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.categoryName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (over)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Over budget',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  PhosphorIconsRegular.pencil,
                  size: 18,
                  color: Color(0xFF667085),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  PhosphorIconsRegular.trash,
                  size: 18,
                  color: Color(0xFFD92D20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatRupiah(item.spent),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'of ${formatRupiah(item.allocated)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: const Color(0xFFEFF1F5),
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(ratio * 100).round()}% used',
                style: TextStyle(fontSize: 11, color: color),
              ),
              Text(
                over
                    ? 'Over by ${formatRupiah(item.remaining.abs())}'
                    : '${formatRupiah(item.remaining)} left',
                style: TextStyle(
                  fontSize: 11,
                  color: over
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
