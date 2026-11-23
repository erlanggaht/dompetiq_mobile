import 'package:flutter_application_1/core/format.dart';

const _wib = Duration(hours: 7);

Map<String, dynamic> mapTransaction(Map<String, dynamic> r) {
  if (r['kind'] == 'SAVINGS_GOAL_TRANSFER') {
    final date = DateTime.parse(r['transactionDate']).toUtc().add(_wib);
    final isOut = r['direction'] == 'OUT';
    return {
      'transactionId': r['transactionId'],
      'title': r['title'] ?? 'Transfer ke Saving Goal',
      'dateTime': date,
      'date': formatDateShort(date),
      'amount':
          '${isOut ? '-' : '+'} ${formatRupiah((r['amount'] as num).toInt())}',
      'isIncome': !isOut,
      'isTransfer': true,
      'category': 'Transfer',
      'categoryLabel': r['goalName'] ?? 'Saving Goal',
    };
  }
  final isIncome = r['type'] == 'Income';
  final category = r['categoryUser']?['category']?['name'] ?? '';
  final note = (r['note'] as String?) ?? '';
  final date = DateTime.parse(r['transactionDate']).toUtc().add(_wib);

  return {
    'transactionId': r['transactionId'],
    'title': note.isNotEmpty ? note : _categoryTitle(category),
    'dateTime': date,
    'date': formatDateShort(date),
    'amount':
        '${isIncome ? '+' : '-'} ${formatRupiah((r['amount'] as num).toInt())}',
    'isIncome': isIncome,
    'isTransfer': false,
    'category': category,
    'categoryLabel': _categoryTitle(category),
  };
}

String _categoryTitle(String name) => name.isEmpty
    ? 'Transaction'
    : name
          .toLowerCase()
          .replaceAll('_', ' ')
          .replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m[0]!.toUpperCase());

List<Map<String, dynamic>> appendUnique(
  List<Map<String, dynamic>> current,
  List<Map<String, dynamic>> incoming,
) {
  final seen = current.map((e) => e['transactionId']).toSet();
  return [...current, ...incoming.where((e) => seen.add(e['transactionId']))];
}
