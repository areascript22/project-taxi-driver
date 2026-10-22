import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../core/error/errors.dart';

/// Traduce lo que lanza `geolocator` al motivo que se le explica al conductor.
///
/// Antes TODO error de `getCurrentPosition()` salia como `unexpected`, y el
/// conductor podia estar "en linea" sin ubicacion sin que nada se lo dijera: la
/// causa real solo quedaba en el log.
///
/// Es una funcion pura para probarla sin GPS ni plugin. Distingue tres causas
/// que el conductor arregla de forma distinta:
///   - ubicacion del dispositivo apagada o en un modo que no alcanza (la
///     excepcion dice "location service ... disabled" aunque el interruptor
///     general figure encendido: pasa, por ejemplo, con la alta precision
///     apagada),
///   - permiso de ubicacion denegado,
///   - sin posicion a tiempo (interior, mala senal).
FailureCode locationFailureCodeOf(Object error) {
  if (error is LocationServiceDisabledException) {
    return FailureCode.gpsDisabled;
  }
  if (error is PermissionDeniedException) {
    return FailureCode.locationPermissionDenied;
  }
  if (error is TimeoutException) {
    return FailureCode.locationUnavailable;
  }
  return FailureCode.unexpected;
}
