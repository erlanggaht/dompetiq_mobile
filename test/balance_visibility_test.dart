import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    BalanceVisibility.visible.value = true;
    await BalanceVisibility.load();
  });

  test('visibility is stored per account', () async {
    await BalanceVisibility.useAccount(1);
    expect(BalanceVisibility.visible.value, isTrue);

    await BalanceVisibility.toggle();
    expect(BalanceVisibility.visible.value, isFalse);

    await BalanceVisibility.useAccount(2);
    expect(BalanceVisibility.visible.value, isTrue);

    await BalanceVisibility.useAccount(1);
    expect(BalanceVisibility.visible.value, isFalse);
  });
}
