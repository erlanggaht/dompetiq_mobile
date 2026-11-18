import 'package:flutter_application_1/feat/transaction/transaction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('apiDate pads month and day for the backend filter', () {
    expect(apiDate(DateTime(2026, 1, 5)), '01-05-2026');
    expect(apiDate(DateTime(2026, 11, 17)), '11-17-2026');
  });
}
