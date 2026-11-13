import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/device_id.dart';

void main() {
  test('generated deviceId is a valid UUID v4', () {
    final id = generateUuidV4();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(id),
      isTrue,
      reason: 'format UUID v4 tidak valid: $id',
    );
  });
}
