import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/core/network/server_error.dart';
import 'package:flutter_application_1/feat/budget/budget_model.dart';
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

  final VoidCallback? onChanged;

  const BudgetScreen({
    super.key,
    this.onChanged,
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
  List<BudgetPeriod> _periods = [];
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
        _periods = results[0].map(BudgetPeriod.fromJson).toList();
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
  BudgetPeriod? get _current {
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
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    shadowColor: colors.accent.withValues(alpha: 0.3),
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
          color: context.appColors.grey,
        ),
        const SizedBox(height: 12),
        Text(
          'No budget yet',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Add an allocation for a spending category',
          style: TextStyle(fontSize: 13, color: context.appColors.grey),
        ),
      ],
    ),
  );

  Future<void> _openEditor(BudgetItem? item) async {
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.grey,
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
                                      widget.onChanged?.call();
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
                              backgroundColor: context.appColors.accent,
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

  Future<void> _delete(BudgetItem item) async {
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
              backgroundColor: context.appColors.danger,
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
      widget.onChanged?.call();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class _PeriodToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _segment(context, 'Monthly', 'monthly'),
          _segment(context, 'Weekly', 'weekly'),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, String value) {
    final colors = context.appColors;
    final active = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: colors.ink.withValues(alpha: 0.05),
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
              color: active ? colors.ink : colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BudgetPeriod? period;

  const _SummaryCard({required this.period});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
              style: TextStyle(color: colors.grey, fontSize: 12),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.accent, colors.accent.withValues(alpha: 0.72)],
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
  final BudgetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = item.allocated == 0
        ? 0.0
        : (item.spent / item.allocated).clamp(0.0, 1.0);
    final color = ratio >= 1
        ? colors.danger
        : ratio >= 0.7
        ? colors.accent
        : colors.accent;
    final over = item.remaining < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colors.border
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.05),
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
                    color: colors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Over budget',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.danger,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  PhosphorIconsRegular.pencil,
                  size: 18,
                  color: colors.grey,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  PhosphorIconsRegular.trash,
                  size: 18,
                  color: colors.danger,
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
                style: TextStyle(fontSize: 12, color: colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: colors.border,
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
                  color: over ? colors.danger : colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
