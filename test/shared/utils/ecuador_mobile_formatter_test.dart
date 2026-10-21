import 'package:driver_app/shared/utils/ecuador_mobile_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = EcuadorMobileFormatter();

  String type(String text) =>
      formatter
          .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
          .text;

  group('digitsOf', () {
    test('keeps a number without the national 0', () {
      expect(EcuadorMobileFormatter.digitsOf(text: '967340047'), '967340047');
    });

    test('drops the national leading 0 so the full number fits', () {
      expect(EcuadorMobileFormatter.digitsOf(text: '0967340047'), '967340047');
    });

    test('ignores spaces and non-digits', () {
      expect(EcuadorMobileFormatter.digitsOf(text: '096 734-004 7'), '967340047');
    });

    test('caps at 9 digits', () {
      expect(EcuadorMobileFormatter.digitsOf(text: '96734004799'), '967340047');
    });

    test('empty and lone 0 give empty', () {
      expect(EcuadorMobileFormatter.digitsOf(text: ''), '');
      expect(EcuadorMobileFormatter.digitsOf(text: '0'), '');
    });
  });

  group('formatEditUpdate', () {
    test('groups digits in threes', () {
      expect(type('9'), '9');
      expect(type('967'), '967');
      expect(type('9673'), '967 3');
      expect(type('967340'), '967 340');
      expect(type('967340047'), '967 340 047');
    });

    test('a number typed with the leading 0 shows all 9 digits', () {
      expect(type('0967340047'), '967 340 047');
    });

    test('puts the cursor at the end', () {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '9673'),
      );
      expect(value.selection.baseOffset, value.text.length);
    });
  });
}
