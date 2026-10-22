import 'package:driver_app/feature/dispatch_admin/domain/dispatch_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatKm', () {
    test('whole kilometres have no decimals', () {
      expect(formatKm(meters: 3000), '3');
      expect(formatKm(meters: 50000), '50');
    });

    test('fractions keep only the meaningful digits', () {
      expect(formatKm(meters: 3500), '3.5');
      expect(formatKm(meters: 250), '0.25');
      expect(formatKm(meters: 100), '0.1');
      expect(formatKm(meters: 3125), '3.125');
    });
  });

  group('parseKmToMeters', () {
    test('accepts a dot or a comma as the decimal separator', () {
      expect(parseKmToMeters(text: '3.5'), 3500);
      expect(parseKmToMeters(text: '3,5'), 3500);
    });

    test('trims spaces and rounds to whole meters', () {
      expect(parseKmToMeters(text: ' 2 '), 2000);
      expect(parseKmToMeters(text: '0.1234'), 123);
    });

    test('returns null for text that is not a non-negative number', () {
      expect(parseKmToMeters(text: ''), isNull);
      expect(parseKmToMeters(text: 'abc'), isNull);
      expect(parseKmToMeters(text: '-1'), isNull);
    });

    test('round-trips with formatKm', () {
      for (final meters in [100, 250, 3000, 3500, 9999, 50000]) {
        expect(parseKmToMeters(text: formatKm(meters: meters)), meters);
      }
    });
  });

  group('parseWholeNumber', () {
    test('parses integers and trims spaces', () {
      expect(parseWholeNumber(text: '12'), 12);
      expect(parseWholeNumber(text: ' 7 '), 7);
    });

    test('returns null for anything else', () {
      expect(parseWholeNumber(text: ''), isNull);
      expect(parseWholeNumber(text: '1.5'), isNull);
      expect(parseWholeNumber(text: 'x'), isNull);
    });
  });
}
