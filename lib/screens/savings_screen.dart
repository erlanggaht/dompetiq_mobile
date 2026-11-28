import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/core/network/server_error.dart';
import 'package:flutter_application_1/feat/savings/savings_service.dart';
import 'package:flutter_application_1/widgets/amount_field.dart';
import 'package:flutter_application_1/widgets/app_section_header.dart';
import 'package:flutter_application_1/widgets/app_bottom_nav.dart';
import 'package:flutter_application_1/widgets/savings_transfer_sheet.dart';

class SavingsScreen extends StatefulWidget {
  final VoidCallback? onChanged;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final bool hasUnreadNotifications;
  final bool showBottomNav;
  final ValueChanged<bool>? onServerError;

  const SavingsScreen({
    super.key,
    this.onChanged,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.hasUnreadNotifications = false,
    this.showBottomNav = false,
    this.onServerError,
  });

  @override
  State<SavingsScreen> createState() => SavingsScreenState();
}

class SavingsScreenState extends State<SavingsScreen> {
  final _service = SavingsService();
  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _accounts = [];
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
      final data = await _service.load();
      if (!mounted) return;
      setState(() {
        _goals = (data['goals'] as List? ?? []).cast<Map<String, dynamic>>();
        _accounts = (data['accounts'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
        _hasData = true;
        _error = null;
      });
      widget.onServerError?.call(false);
    } catch (e) {
      if (!mounted) return;
      final serverError = isServerConnectionError(e);
      widget.onServerError?.call(serverError);
      final message = _message(e);
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

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _changed() {
    widget.onChanged?.call();
    _load(showLoading: false);
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
                  title: 'Savings Goals',
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
                  label: const Text('Add goal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.piggyBank,
              size: 44,
              color: context.appColors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No savings goal yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Tap + to create a target',
              style: TextStyle(fontSize: 13, color: context.appColors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [for (final goal in _goals) _goalCard(goal)],
      ),
    );
  }

  Widget _goalCard(Map<String, dynamic> goal) {
    final colors = context.appColors;
    final target = (goal['target'] as num?)?.toInt() ?? 0;
    final saved = (goal['saved'] as num?)?.toInt() ?? 0;
    final ratio = target == 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
    final reached = saved >= target;
    final deadline = DateTime.tryParse(goal['deadline'] as String? ?? '')
        ?.toLocal();

    return InkWell(
      onTap: () => _openActions(goal),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                    goal['name'] as String? ?? '',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                if (reached)
                  Text(
                    'Reached',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: colors.border,
                color: reached ? colors.green : colors.accent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatRupiah(saved),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'of ${formatRupiah(target)}',
                  style: TextStyle(fontSize: 12, color: colors.grey),
                ),
              ],
            ),
            if (deadline != null) ...[
              const SizedBox(height: 6),
              Text(
                'Deadline ${formatDateShort(deadline)}',
                style: TextStyle(fontSize: 11, color: colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sheet(
    List<Widget> Function(BuildContext context, StateSetter setSheet) builder, {
    Widget Function(BuildContext context, StateSetter setSheet)? bottom,
  }) {
    return showModalBottomSheet<void>(
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
        builder: (context, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    bottom == null
                        ? MediaQuery.of(context).viewInsets.bottom + 24
                        : 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: builder(context, setSheet),
                  ),
                ),
              ),
            ),
            if (bottom != null) bottom(context, setSheet),
          ],
        ),
      ),
    );
  }

  Future<void> _openActions(Map<String, dynamic> goal) async {
    await _sheet(
      (context, setSheet) => [
        Text(
          goal['name'] as String? ?? '',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            PhosphorIconsRegular.plusCircle,
            color: context.appColors.accent,
          ),
          title: const Text('Add money'),
          onTap: () {
            Navigator.pop(context);
            _openTransfer(goal);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(PhosphorIconsRegular.clockCounterClockwise),
          title: const Text('History'),
          onTap: () {
            Navigator.pop(context);
            _openHistory(goal);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(PhosphorIconsRegular.pencilSimple),
          title: const Text('Edit goal'),
          onTap: () {
            Navigator.pop(context);
            _openEditor(goal);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            PhosphorIconsRegular.trash,
            color: context.appColors.danger,
          ),
          title: Text(
            'Delete goal',
            style: TextStyle(color: context.appColors.danger),
          ),
          onTap: () {
            Navigator.pop(context);
            _delete(goal);
          },
        ),
      ],
    );
  }

  Future<void> _openEditor(Map<String, dynamic>? goal) async {
    final nameController = TextEditingController(
      text: goal?['name'] as String? ?? '',
    );
    final targetController = TextEditingController(
      text: goal == null
          ? ''
          : formatThousands((goal['target'] as num).toInt()),
    );
    DateTime? deadline = DateTime.tryParse(goal?['deadline'] as String? ?? '')
        ?.toLocal();
    bool saving = false;
    final keys = AmountKeys(targetController);
    bool showKeypad = true;

    await _sheet(
      (context, setSheet) => [
        Text(
          goal == null ? 'New savings goal' : 'Edit savings goal',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        AmountField(
          controller: targetController,
          label: 'Target',
          useInternalKeypad: false,
          autofocus: true,
          onTap: () => setSheet(() => showKeypad = true),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: deadline ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setSheet(() => deadline = picked);
                },
                icon: const Icon(PhosphorIconsRegular.calendarBlank, size: 18),
                label: Text(
                  deadline == null
                      ? 'No deadline'
                      : 'Deadline ${formatDateShort(deadline!)}',
                ),
              ),
            ),
            if (deadline != null)
              IconButton(
                onPressed: () => setSheet(() => deadline = null),
                icon: const Icon(PhosphorIconsRegular.x),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final name = nameController.text.trim();
                    final target =
                        int.tryParse(
                          targetController.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          ),
                        ) ??
                        0;
                    if (name.isEmpty || target <= 0) {
                      _showMessage('Enter a name and a target amount');
                      return;
                    }
                    setSheet(() => saving = true);
                    try {
                      await _service.save(
                        id: (goal?['id'] as num?)?.toInt(),
                        name: name,
                        target: target,
                        deadline: deadline,
                      );
                      if (context.mounted) Navigator.pop(context);
                      _changed();
                    } catch (e) {
                      setSheet(() => saving = false);
                      _showMessage(_message(e));
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.accent,
            ),
            child: Text(saving ? 'Saving...' : 'Save'),
          ),
        ),
      ],
      bottom: (sheetContext, setSheet) => showKeypad
          ? AmountKeypad(
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
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _openTransfer(Map<String, dynamic> goal) async {
    final added = await showSavingsTransferSheet(
      context: context,
      goal: goal,
      accounts: _accounts,
      service: _service,
    );
    if (added) _changed();
  }

  Future<void> _openHistory(Map<String, dynamic> goal) async {
    final id = (goal['id'] as num?)?.toInt();
    final name = goal['name'] as String? ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.activity(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(_message(snapshot.error!)));
              }
              final items =
                  (snapshot.data ?? []).where((item) {
                    final goalId = item['savingsGoalId'] ?? item['goalId'];
                    return goalId != null
                        ? goalId == id
                        : item['goalName'] == name;
                  }).toList()..sort(
                    (a, b) => (b['transactionDate'] as String? ?? '').compareTo(
                      a['transactionDate'] as String? ?? '',
                    ),
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'History · $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              'No activity yet',
                              style: TextStyle(color: context.appColors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final date = DateTime.tryParse(
                                item['transactionDate'] as String? ?? '',
                              )?.toLocal();
                              final amount =
                                  (item['amount'] as num?)?.toInt() ?? 0;
                              final added = item['direction'] != 'IN';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  added ? 'Added to goal' : 'Withdrawn',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: date == null
                                    ? null
                                    : Text(formatDateShort(date)),
                                trailing: Text(
                                  '${added ? '+' : '-'} ${formatRupiah(amount)}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: added
                                        ? context.appColors.accent
                                        : context.appColors.danger,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('Remove the "${goal['name']}" goal.'),
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
      await _service.delete((goal['id'] as num).toInt());
      _changed();
    } catch (e) {
      _showMessage(_message(e));
    }
  }
}
