String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i - 1;
    buffer.write(digits[i]);
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  final body = 'Rp. $buffer';
  return amount < 0 ? '- $body' : body;
}

String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i - 1;
    buffer.write(digits[i]);
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return buffer.toString();
}

const _months = [
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

String formatDateShort(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  return '$d ${_months[date.month - 1]} ${date.year}';
}

String formatDayLabel(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now().toUtc().add(const Duration(hours: 7));
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return formatDateShort(date);
}
