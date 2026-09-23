import 'package:driver_app/core/error/errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('exposes the message it was created with', () {
      final failure = Failure(message: 'algo salió mal');

      expect(failure.message, 'algo salió mal');
    });

    test('is an ErrorBase', () {
      final failure = Failure(message: 'x');

      expect(failure, isA<ErrorBase>());
    });

    test('two instances with the same message are distinct objects', () {
      final a = Failure(message: 'igual');
      final b = Failure(message: 'igual');

      expect(identical(a, b), isFalse);
      expect(a.message, b.message);
    });

    test('supports an empty message', () {
      final failure = Failure(message: '');

      expect(failure.message, '');
    });
  });
}
