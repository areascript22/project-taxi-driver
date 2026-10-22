import 'package:driver_app/feature/auth/presentation/util/auth_input_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isEmailFormatValid', () {
    test('accepts ordinary addresses, ignoring surrounding spaces', () {
      expect(isEmailFormatValid(email: 'driver@example.com'), isTrue);
      expect(isEmailFormatValid(email: '  a.b+c@mail.co.ec '), isTrue);
    });

    test('rejects empty, missing @, missing domain dot and inner spaces', () {
      expect(isEmailFormatValid(email: ''), isFalse);
      expect(isEmailFormatValid(email: 'driver.example.com'), isFalse);
      expect(isEmailFormatValid(email: 'driver@example'), isFalse);
      expect(isEmailFormatValid(email: 'dri ver@example.com'), isFalse);
      expect(isEmailFormatValid(email: '@example.com'), isFalse);
    });
  });

  test('minPasswordLength matches the Firebase Auth minimum', () {
    expect(minPasswordLength, 6);
  });
}
