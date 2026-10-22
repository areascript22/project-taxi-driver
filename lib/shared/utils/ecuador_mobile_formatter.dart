import 'package:flutter/services.dart';

/// Celular ecuatoriano: se muestra en grupos de 3 ("967 340 047") junto al
/// prefijo +593.
///
/// El 0 inicial del formato nacional (0967340047) se acepta al escribir o
/// pegar pero no se conserva: con +593 delante sobra, y dejarlo hacia que el
/// campo de 9 digitos se quedara sin sitio para el ultimo numero.
class EcuadorMobileFormatter extends TextInputFormatter {
  const EcuadorMobileFormatter();

  /// Largo del numero sin el 0 nacional ni el +593.
  static const int nationalLength = 9;

  /// Solo los digitos del numero, sin 0 inicial y recortado a [nationalLength].
  static String digitsOf({required String text}) {
    var digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.length > nationalLength
        ? digits.substring(0, nationalLength)
        : digits;
  }

  /// "967340047" -> "967 340 047".
  static String format({required String digits}) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = format(digits: digitsOf(text: newValue.text));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
