import '../../../core/error/errors.dart';

/// Evento con el que el isolate del foreground service le avisa a la app de que
/// cambió su capacidad de obtener la ubicación.
const locationStatusEvent = 'locationStatus';

/// Evento con el que la app le pide al servicio que repita su estado actual. La
/// pantalla (y su bloc) se recrean al entrar, así que sin esto no sabrían de un
/// problema que ya empezó antes.
const queryLocationStatusEvent = 'queryLocationStatus';

/// El mensaje que viaja del isolate a la app: el motivo por el que NO hay
/// ubicación, o null cuando ya la hay.
Map<String, dynamic> encodeLocationIssue(FailureCode? issue) => {
  'issue': issue?.name,
};

FailureCode? decodeLocationIssue(Map<String, dynamic>? event) {
  final name = event?['issue'];
  if (name is! String) return null;
  for (final code in FailureCode.values) {
    if (code.name == name) return code;
  }
  return null;
}

/// Resultado de registrar una lectura del GPS.
class LocationIssueUpdate {
  const LocationIssueUpdate({required this.changed, required this.issue});

  /// true si hay algo NUEVO que contarle a la app (empezó o se resolvió un
  /// problema, o cambió el motivo). false: no repetir el mismo aviso.
  final bool changed;

  /// El problema vigente, o null si la ubicación funciona.
  final FailureCode? issue;
}

/// Decide cuándo avisarle al conductor de que no hay ubicación.
///
/// Sin esto el conductor podía estar "en línea" sin que el servicio consiguiera
/// su posición, y nada se lo decía: el servidor no le ofrecía pedidos (descarta
/// ubicaciones de más de 45 s) y la causa solo quedaba en el log.
///
/// Un fallo suelto no es un problema (un GPS que tarda en fijar, un túnel): hay
/// que [failureThreshold] fallos SEGUIDOS para avisar, y una sola lectura buena
/// lo resuelve. Es una clase pura (sin plugins ni reloj) para probarla sin GPS.
class LocationIssueTracker {
  LocationIssueTracker({this.failureThreshold = 3});

  final int failureThreshold;
  int _consecutiveFailures = 0;
  FailureCode? _announced;

  /// El problema que ya se anunció, o null.
  FailureCode? get announced => _announced;

  LocationIssueUpdate onFailure({required FailureCode code}) {
    _consecutiveFailures++;
    if (_consecutiveFailures < failureThreshold) {
      return LocationIssueUpdate(changed: false, issue: _announced);
    }

    // Un error desconocido igual significa "no tengo ubicación": se le dice así
    // al conductor en vez de un mensaje genérico que no le sirve.
    final issue =
        code == FailureCode.unexpected ? FailureCode.locationUnavailable : code;
    final changed = _announced != issue;
    _announced = issue;
    return LocationIssueUpdate(changed: changed, issue: issue);
  }

  LocationIssueUpdate onSuccess() {
    _consecutiveFailures = 0;
    final changed = _announced != null;
    _announced = null;
    return LocationIssueUpdate(changed: changed, issue: null);
  }
}
