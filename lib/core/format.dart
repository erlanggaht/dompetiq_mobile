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

String formatUsername(String? username, {String fallback = 'dompetiq'}) {
  final value = username?.trim().replaceFirst(RegExp(r'^@+'), '') ?? '';
  return '@${value.isEmpty ? fallback : value}';
}

DateTime? parseApiDate(String value) {
  final parts = value.trim().split('-');
  if (parts.length != 3) return null;
  final month = int.tryParse(parts[0]);
  final day = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (month == null || day == null || year == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

String formatDayLabel(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now().toUtc().add(const Duration(hours: 7));
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  final short = '${date.day} ${_months[date.month - 1]}';
  if (diff == 0) return 'Today, $short';
  if (diff == 1) return 'Yesterday, $short';
  return formatDateShort(date);
}
