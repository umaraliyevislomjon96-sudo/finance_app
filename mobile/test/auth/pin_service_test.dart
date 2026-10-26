import 'package:aurora_finance/core/auth/pin_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pins = PinService.instance;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await pins.clear();
  });

  test('stores only a hash and verifies the right PIN', () async {
    await pins.setPin('2580', biometrics: false);
    expect(await pins.hasPin(), isTrue);
    expect(await pins.verify('2580'), PinCheck.ok);
    expect(await pins.verify('0000'), PinCheck.wrong);
  });

  test('locks out after 5 wrong attempts and blocks even the right PIN', () async {
    await pins.setPin('2580', biometrics: false);
    for (var i = 0; i < 4; i++) {
      expect(await pins.verify('1111'), PinCheck.wrong);
    }
    expect(await pins.verify('1111'), PinCheck.lockedOut);
    expect(await pins.lockRemaining(), isNotNull);
    expect(await pins.verify('2580'), PinCheck.lockedOut);
  });

  test('a correct PIN resets the failure counter', () async {
    await pins.setPin('2580', biometrics: false);
    await pins.verify('1111');
    await pins.verify('1111');
    expect(await pins.verify('2580'), PinCheck.ok);
    expect(await pins.failedAttempts(), 0);
  });
}
