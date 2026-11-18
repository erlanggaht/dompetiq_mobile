import 'package:flutter_application_1/feat/transaction/transaction_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _record({
  String note = 'Makan siang',
  String type = 'Spending',
  int amount = 35000,
  String category = 'FOOD_AND_DRINK',
  String date = '2026-11-17T05:00:00.000Z',
}) => {
  'transactionId': 'TRX-1',
  'type': type,
  'amount': amount,
  'note': note,
  'transactionDate': date,
  'categoryUser': {
    'category': {'id': 3, 'name': category},
  },
};

void main() {
  test('maps spending to negative amount and WIB date', () {
    final item = mapTransaction(_record());

    expect(item['transactionId'], 'TRX-1');
    expect(item['title'], 'Makan siang');
    expect(item['amount'], '- Rp. 35.000');
    expect(item['isIncome'], isFalse);
    expect(item['date'], '17 Nov 2026');
    expect((item['dateTime'] as DateTime).hour, 12);
    expect(item['categoryLabel'], 'Food and drink');
  });

  test('maps income to positive amount', () {
    final item = mapTransaction(
      _record(type: 'Income', amount: 8500000, note: 'Gaji'),
    );

    expect(item['amount'], '+ Rp. 8.500.000');
    expect(item['isIncome'], isTrue);
  });

  test('falls back to category title when note is empty', () {
    final item = mapTransaction(_record(note: ''));

    expect(item['title'], 'Food and drink');
    expect(item['categoryLabel'], 'Food and drink');
  });

  test('uses Transaction when category is missing', () {
    final item = mapTransaction({
      'transactionId': 'TRX-2',
      'type': 'Income',
      'amount': 1000,
      'transactionDate': '2026-11-17T05:00:00.000Z',
    });

    expect(item['title'], 'Transaction');
  });

  test('shifts transactionDate to WIB across midnight', () {
    final item = mapTransaction(
      _record(date: '2026-11-17T17:30:00.000Z', note: 'Tengah malam'),
    );

    expect(item['date'], '18 Nov 2026');
    expect((item['dateTime'] as DateTime).hour, 0);
    expect((item['dateTime'] as DateTime).minute, 30);
  });
}
