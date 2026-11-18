import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/format.dart';

void main() {
  test('formatRupiah groups thousands with dots', () {
    expect(formatRupiah(3200000), 'Rp. 3.200.000');
    expect(formatRupiah(35000), 'Rp. 35.000');
    expect(formatRupiah(500), 'Rp. 500');
    expect(formatRupiah(-12000), '- Rp. 12.000');
  });

  test('formatDateShort renders dd MMM yyyy', () {
    expect(formatDateShort(DateTime(2026, 11, 10)), '10 Nov 2026');
  });

  test('formatUsername avoids duplicate at signs', () {
    expect(formatUsername('@erlangga'), '@erlangga');
    expect(formatUsername(''), '@dompetiq');
  });

  test('formatDayLabel names today and yesterday', () {
    final now = DateTime(2026, 11, 17, 9);
    expect(
      formatDayLabel(DateTime(2026, 11, 17, 23), now: now),
      'Today, 17 Nov',
    );
    expect(
      formatDayLabel(DateTime(2026, 11, 16, 1), now: now),
      'Yesterday, 16 Nov',
    );
    expect(formatDayLabel(DateTime(2026, 11, 10), now: now), '10 Nov 2026');
  });
}
