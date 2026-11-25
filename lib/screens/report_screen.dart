import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/network/server_error.dart';
import 'package:flutter_application_1/feat/report/report_service.dart';
import 'package:flutter_application_1/widgets/app_section_header.dart';
import 'package:flutter_application_1/widgets/app_bottom_nav.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String reportMonthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

String reportMonthLabel(DateTime date) =>
    '${_months[date.month - 1]} ${date.year}';

class ReportScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final bool hasUnreadNotifications;
  final bool showBottomNav;
  final ValueChanged<bool>? onServerError;

  const ReportScreen({
    super.key,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.hasUnreadNotifications = false,
    this.showBottomNav = false,
    this.onServerError,
  });

  @override
  State<ReportScreen> createState() => ReportScreenState();
}

class ReportScreenState extends State<ReportScreen> {
  final _service = ReportService();
  late final DateTime _now;
  late DateTime _month;
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _hasData = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _month = DateTime(_now.year, _now.month);
    _load();
  }

  Future<void> _load() async {
    if (!_hasData) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _service.monthlySummary(reportMonthKey(_month));
      if (!mounted) return;
      setState(() {
        _data = data;
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
        if (!serverError && mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      } else {
        setState(() {
          _loading = false;
          _error = message;
        });
      }
    }
  }

  Future<void> reload() => _load();

  void _shiftMonth(int offset) {
    setState(() => _month = DateTime(_month.year, _month.month + offset));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(onHome: () => Navigator.pop(context))
          : null,
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              title: 'Monthly Report',
              onOpenMenu: widget.onOpenMenu,
              onOpenNotifications: widget.onOpenNotifications,
              hasUnreadNotifications: widget.hasUnreadNotifications,
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

    final current = _data['current'] as Map<String, dynamic>? ?? {};
    final categories = (_data['categories'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final trend = (_data['trend'] as List? ?? []).cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _monthSelector(),
          const SizedBox(height: 20),
          _summaryCard(current),
          const SizedBox(height: 24),
          const Text(
            'By category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            _emptyCard('No transactions for this month')
          else
            ...categories.map(_categoryCard),
          const SizedBox(height: 24),
          const Text(
            'Last 6 months',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _trendCard(trend),
        ],
      ),
    );
  }

  Widget _monthSelector() => Row(
    children: [
      IconButton(
        onPressed: () => _shiftMonth(-1),
        icon: const Icon(PhosphorIconsRegular.caretLeft),
      ),
      Expanded(
        child: Text(
          reportMonthLabel(_month),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      IconButton(
        onPressed: _month.year == _now.year && _month.month == _now.month
            ? null
            : () => _shiftMonth(1),
        icon: const Icon(PhosphorIconsRegular.caretRight),
      ),
    ],
  );

  Widget _summaryCard(Map<String, dynamic> current) {
    final changes = _data['changes'] as Map<String, dynamic>? ?? {};
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
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
      child: Row(
        children: [
          _stat(
            'Income',
            current['income'],
            changes['income'],
            const Color(0xFF16A34A),
          ),
          _divider(),
          _stat(
            'Spending',
            current['spending'],
            changes['spending'],
            const Color(0xFFDC2626),
          ),
          _divider(),
          _stat('Net', current['net'], null, const Color(0xFF3B62FF)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 52, color: const Color(0xFFEDEEF3));

  Widget _stat(String label, dynamic value, dynamic change, Color color) {
    final amount = (value as num?)?.toInt() ?? 0;
    final percent = change == null
        ? null
        : '${change > 0 ? '+' : ''}${(change as num).round()}%';
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 6),
          Text(
            formatRupiah(amount),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (percent != null) ...[
            const SizedBox(height: 4),
            Text(
              percent,
              style: const TextStyle(fontSize: 10, color: Color(0xFF98A2B3)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryCard(Map<String, dynamic> category) {
    final amount = (category['amount'] as num?)?.toInt() ?? 0;
    final percent = (category['percent'] as num?)?.toDouble() ?? 0;
    final isIncome = category['type'] == 'Income';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                  category['name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatRupiah(amount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isIncome
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF1C1C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 100) / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFEDEEF3),
              color: isIncome
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${percent.round()}%',
            style: const TextStyle(fontSize: 10, color: Color(0xFF98A2B3)),
          ),
        ],
      ),
    );
  }

  Widget _trendCard(List<Map<String, dynamic>> trend) {
    final max = trend.fold<double>(0, (value, item) {
      final income = (item['income'] as num?)?.toDouble() ?? 0;
      final spending = (item['spending'] as num?)?.toDouble() ?? 0;
      return value > income && value > spending
          ? value
          : income > spending
          ? income
          : spending;
    });
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [for (final item in trend) _trendColumn(item, max)],
      ),
    );
  }

  Widget _trendColumn(Map<String, dynamic> item, double max) {
    final key = item['month'] as String? ?? '';
    final label = key.length >= 7
        ? _shortMonths[int.parse(key.substring(5, 7)) - 1]
        : key;
    final income = (item['income'] as num?)?.toDouble() ?? 0;
    final spending = (item['spending'] as num?)?.toDouble() ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(income, max, const Color(0xFF16A34A)),
              const SizedBox(width: 4),
              _bar(spending, max, const Color(0xFFDC2626)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF667085)),
        ),
      ],
    );
  }

  Widget _bar(double value, double max, Color color) {
    final height = max == 0 ? 0.0 : (value / max) * 56;
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }

  Widget _emptyCard(String message) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
    ),
  );
}
