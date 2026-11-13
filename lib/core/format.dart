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
