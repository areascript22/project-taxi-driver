/// Metros -> el texto en km que ve y edita la persona: "3", "3.5", "0.25".
/// Sin ceros de sobra (el servidor guarda metros enteros).
String formatKm({required int meters}) {
  if (meters % 1000 == 0) return '${meters ~/ 1000}';
  final text = (meters / 1000).toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

/// Lo que la persona escribió en km -> metros. Acepta coma o punto decimal
/// (un teclado en español pone coma). null si no es un número.
int? parseKmToMeters({required String text}) {
  final km = double.tryParse(text.trim().replaceAll(',', '.'));
  if (km == null || km.isNaN || km.isInfinite || km < 0) return null;
  return (km * 1000).round();
}

/// Lo que la persona escribió -> entero. null si no es un entero.
int? parseWholeNumber({required String text}) {
  return int.tryParse(text.trim());
}
