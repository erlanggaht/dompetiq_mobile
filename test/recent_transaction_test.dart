import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/widgets/recent_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _item({
  required String id,
  required String title,
  required DateTime date,
  bool isIncome = false,
}) => {
  'transactionId': id,
  'title': title,
  'dateTime': date,
  'date': '17 Nov 2026',
  'amount': isIncome ? '+ Rp. 10.000' : '- Rp. 10.000',
  'isIncome': isIncome,
  'category': 'FOOD_AND_DRINK',
  'categoryLabel': 'Food and drink',
};

DateTime get _todayWib {
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  return DateTime(now.year, now.month, now.day, 12);
}

class _Host extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool grouped;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onDelete;

  const _Host({
    required this.items,
    this.grouped = false,
    this.onTap,
    this.onDelete,
  });

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late final List<Map<String, dynamic>> _items = List.of(widget.items);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF2F4F9),
        body: SingleChildScrollView(
          child: RecentTransactionWidget(
            transactions: _items,
            grouped: widget.grouped,
            onTap: widget.onTap,
            onDelete: widget.onDelete == null ? null : _delete,
          ),
        ),
      ),
    );
  }

  void _delete(String transactionId) {
    widget.onDelete!(transactionId);
    setState(
      () => _items.removeWhere((e) => e['transactionId'] == transactionId),
    );
  }
}

void main() {
  setUp(() => BalanceVisibility.visible.value = true);

  testWidgets('empty list shows empty state', (tester) async {
    await tester.pumpWidget(const _Host(items: []));

    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('ungrouped list has one card and no date labels', (tester) async {
    final today = _todayWib;
    await tester.pumpWidget(
      _Host(
        items: [
          _item(id: 'A', title: 'Makan siang', date: today),
          _item(
            id: 'B',
            title: 'Gaji',
            date: today.subtract(const Duration(days: 1)),
            isIncome: true,
          ),
        ],
      ),
    );

    expect(find.text('Today'), findsNothing);
    expect(find.text('Yesterday'), findsNothing);
    expect(find.text('17 Nov 2026'), findsNWidgets(2));
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('grouped list labels today and yesterday', (tester) async {
    final today = _todayWib;
    await tester.pumpWidget(
      _Host(
        grouped: true,
        items: [
          _item(id: 'A', title: 'Makan siang', date: today),
          _item(
            id: 'B',
            title: 'Gaji',
            date: today.subtract(const Duration(days: 1)),
            isIncome: true,
          ),
        ],
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Food and drink'), findsNWidgets(2));
  });

  testWidgets('hides amounts when balance is locked', (tester) async {
    BalanceVisibility.visible.value = false;
    await tester.pumpWidget(
      _Host(
        items: [
          _item(id: 'A', title: 'Makan siang', date: _todayWib),
          _item(id: 'B', title: 'Gaji', date: _todayWib, isIncome: true),
        ],
      ),
    );

    expect(find.text('••••••'), findsNWidgets(2));
    expect(find.text('- Rp. 10.000'), findsNothing);
  });

  testWidgets('tapping a row reports its transaction id', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      _Host(
        items: [_item(id: 'TRX-9', title: 'Makan siang', date: _todayWib)],
        onTap: tapped.add,
      ),
    );

    await tester.tap(find.text('Makan siang'));
    await tester.pumpAndSettle();

    expect(tapped, ['TRX-9']);
  });

  testWidgets('swipe then cancel keeps the row', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(
      _Host(
        items: [_item(id: 'A', title: 'Makan siang', date: _todayWib)],
        onDelete: deleted.add,
      ),
    );

    await tester.drag(find.text('Makan siang'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete transaction?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(deleted, isEmpty);
    expect(find.text('Makan siang'), findsOneWidget);
  });

  testWidgets('swipe then confirm deletes the row', (tester) async {
    final deleted = <String>[];
    await tester.pumpWidget(
      _Host(
        items: [_item(id: 'A', title: 'Makan siang', date: _todayWib)],
        onDelete: deleted.add,
      ),
    );

    await tester.drag(find.text('Makan siang'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deleted, ['A']);
    expect(find.text('Makan siang'), findsNothing);
    expect(find.text('No transactions yet'), findsOneWidget);
  });
}
