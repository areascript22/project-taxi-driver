/// Cuando vale la pena reportar la ubicacion al servidor.
///
/// Dos fuerzas opuestas:
///   - El GPS tiene ruido de varios metros incluso parado: reportar cada tick
///     seria trafico y bateria desperdiciados.
///   - El servidor solo considera para el despacho a quien reporto hace poco
///     (45 s por defecto): un conductor parado esperando un pedido que no
///     reporta nada deja de recibirlos.
///
/// De ahi la regla: se reporta si se movio lo suficiente, o si ya paso el
/// tiempo del "latido" (aunque este quieto). Es una funcion pura para poder
/// probarla sin GPS ni reloj.
class LocationReportPolicy {
  const LocationReportPolicy({
    this.minMovementMeters = 5.0,
    this.heartbeat = const Duration(seconds: 20),
  });

  /// Movimiento minimo para reportar antes del latido.
  final double minMovementMeters;

  /// Cada cuanto se reporta aunque no se haya movido. Tiene que ser bastante
  /// menor que la frescura que exige el servidor (location_max_age_seconds).
  final Duration heartbeat;

  /// [movedMeters] y [sinceLastReport] se miden contra el ULTIMO reporte
  /// enviado; son null si todavia no se envio ninguno (el primero siempre va).
  bool shouldReport({double? movedMeters, Duration? sinceLastReport}) {
    if (movedMeters == null || sinceLastReport == null) return true;
    if (movedMeters >= minMovementMeters) return true;
    return sinceLastReport >= heartbeat;
  }
}
