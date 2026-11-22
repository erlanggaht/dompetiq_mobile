import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/feat/savings/savings_service.dart';
import 'package:flutter_application_1/widgets/app_page_header.dart';

const _accent = Color(0xFF3B62FF);
const _green = Color(0xFF16A34A);

class SavingsScreen extends StatefulWidget {
  final VoidCallback? onChanged;

  const SavingsScreen({super.key, this.onChanged});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _service = SavingsService();
  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _accounts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
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
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _message(e);
        _loading = false;
      });
    }
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Savings Goals',
              trailing: _loading || _error != null
                  ? null
                  : IconButton(
                      onPressed: () => _openEditor(null),
                      icon: const Icon(
                        PhosphorIconsRegular.plus,
                        color: _accent,
                      ),
                    ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
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
          children: const [
            Icon(
              PhosphorIconsRegular.piggyBank,
              size: 44,
              color: Color(0xFFB9BDD0),
            ),
            SizedBox(height: 12),
            Text(
              'No savings goal yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Tap + to create a target',
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal['name'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (reached)
                  const Text(
                    'Reached',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _green,
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
                backgroundColor: const Color(0xFFEDEEF3),
                color: reached ? _green : _accent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatRupiah(saved),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'of ${formatRupiah(target)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
            if (deadline != null) ...[
              const SizedBox(height: 6),
              Text(
                'Deadline ${formatDateShort(deadline)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF98A2B3)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sheet(
    List<Widget> Function(BuildContext context, StateSetter setSheet) builder,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: builder(context, setSheet),
          ),
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
          leading: const Icon(PhosphorIconsRegular.plusCircle, color: _accent),
          title: const Text('Add money'),
          onTap: () {
            Navigator.pop(context);
            _openTransfer(goal);
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
          leading: const Icon(
            PhosphorIconsRegular.trash,
            color: Color(0xFFD92D20),
          ),
          title: const Text(
            'Delete goal',
            style: TextStyle(color: Color(0xFFD92D20)),
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
        TextField(
          controller: targetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _formatAmount(targetController, value),
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
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: Text(saving ? 'Saving...' : 'Save'),
          ),
        ),
      ],
    );
  }

  Future<void> _openTransfer(Map<String, dynamic> goal) async {
    if (_accounts.isEmpty) {
      _showMessage('No account with a card available');
      return;
    }
    int? accountId = (_accounts.first['id'] as num).toInt();
    final amount = TextEditingController();
    bool saving = false;

    await _sheet(
      (context, setSheet) => [
        Text(
          'Add to ${goal['name']}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<int>(
          initialValue: accountId,
          decoration: const InputDecoration(
            labelText: 'From account',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final account in _accounts)
              DropdownMenuItem<int>(
                value: (account['id'] as num).toInt(),
                child: Text(account['name'] as String),
              ),
          ],
          onChanged: (value) => setSheet(() => accountId = value),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _formatAmount(amount, value),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final value =
                        int.tryParse(
                          amount.text.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    if (value <= 0 || accountId == null) {
                      _showMessage('Choose an account and enter an amount');
                      return;
                    }
                    setSheet(() => saving = true);
                    try {
                      await _service.transfer(
                        goalId: (goal['id'] as num).toInt(),
                        rekeningUserId: accountId!,
                        amount: value,
                        date: DateTime.now(),
                      );
                      if (context.mounted) Navigator.pop(context);
                      _changed();
                    } catch (e) {
                      setSheet(() => saving = false);
                      _showMessage(_message(e));
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: Text(saving ? 'Saving...' : 'Add money'),
          ),
        ),
      ],
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
      await _service.delete((goal['id'] as num).toInt());
      _changed();
    } catch (e) {
      _showMessage(_message(e));
    }
  }
}

void _formatAmount(TextEditingController controller, String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    controller.clear();
    return;
  }
  if (digits.length > 12) return;
  final formatted = formatThousands(int.parse(digits));
  controller.value = TextEditingValue(
    text: formatted,
    selection: TextSelection.collapsed(offset: formatted.length),
  );
}
