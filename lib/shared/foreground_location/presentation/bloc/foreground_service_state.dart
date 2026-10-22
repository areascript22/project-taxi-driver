part of 'foreground_service_bloc.dart';

enum BatteryOptimizationPromptStep {
  // Nada que mostrar.
  none,
  // Mostrar el diálogo explicativo propio antes del diálogo nativo.
  rationale,
  // El diálogo nativo fue rechazado: mostrar el banner persistente con
  // "Reintentar" / "Abrir ajustes" en vez del OfflineNotice normal.
  deniedBanner,
}

@immutable
class ForegroundServiceState {
  final bool isRunning;
  // true mientras se está iniciando/deteniendo -- deshabilita el switch para
  // evitar togglear dos veces mientras el plugin nativo responde.
  final bool isProcessing;
  // true una vez que se consultó el estado real al menos una vez. El bloc se
  // recrea (registerFactory) en cada visita a la pantalla, así que sin esto
  // no se puede distinguir "aún no sé si está online" de "confirmado
  // offline" -- causaría un parpadeo de "estás offline" en cada entrada.
  final bool hasLoadedStatus;
  // Si la app está excluida de la optimización de batería del sistema. Se
  // exige en `true` antes de poder encender el toggle -- sin esto Android
  // puede matar el foreground service si el conductor cierra la app.
  final bool isBatteryOptimizationIgnored;
  final BatteryOptimizationPromptStep batteryPromptStep;
  // Por que no se pudo ponerse en linea (el servidor lo rechazo: cuenta no
  // habilitada, perfil no listo, red; o no hay ubicacion utilizable). Null si
  // no hubo error. La UI lo muestra una vez y lo traduce con
  // `context.failureText`.
  final FailureCode? errorCode;
  // Por que NO hay ubicacion utilizable (GPS o ajustes apagados, permiso, sin
  // senal): al intentar conectarse, o mientras el servicio corre. A diferencia
  // de `errorCode`, PERSISTE hasta que se resuelve: es lo que mantiene visible
  // el aviso "no estas recibiendo pedidos". Null si la ubicacion funciona.
  final FailureCode? locationIssue;
  // true UNA vez cuando, al reconciliar con el servidor, el interruptor se
  // apago porque el servidor tenia al conductor fuera de linea. La UI lo explica
  // con un aviso en vez de apagarlo en silencio.
  final bool disconnectedByServer;

  const ForegroundServiceState({
    this.isRunning = false,
    this.isProcessing = false,
    this.hasLoadedStatus = false,
    this.isBatteryOptimizationIgnored = false,
    this.batteryPromptStep = BatteryOptimizationPromptStep.none,
    this.errorCode,
    this.locationIssue,
    this.disconnectedByServer = false,
  });

  // `errorCode` y `disconnectedByServer` se pasan SIEMPRE tal cual (no con
  // `??`): copiar sin indicarlos los limpia, que es lo que se quiere -- se
  // muestran una vez y no reaparecen en el siguiente cambio de estado.
  //
  // `locationIssue` es al reves: se CONSERVA salvo que se pase uno nuevo o se
  // pida `clearLocationIssue`.
  ForegroundServiceState copyWith({
    bool? isRunning,
    bool? isProcessing,
    bool? hasLoadedStatus,
    bool? isBatteryOptimizationIgnored,
    BatteryOptimizationPromptStep? batteryPromptStep,
    FailureCode? errorCode,
    FailureCode? locationIssue,
    bool clearLocationIssue = false,
    bool disconnectedByServer = false,
  }) {
    return ForegroundServiceState(
      isRunning: isRunning ?? this.isRunning,
      isProcessing: isProcessing ?? this.isProcessing,
      hasLoadedStatus: hasLoadedStatus ?? this.hasLoadedStatus,
      isBatteryOptimizationIgnored:
          isBatteryOptimizationIgnored ?? this.isBatteryOptimizationIgnored,
      batteryPromptStep: batteryPromptStep ?? this.batteryPromptStep,
      errorCode: errorCode,
      locationIssue:
          clearLocationIssue ? null : (locationIssue ?? this.locationIssue),
      disconnectedByServer: disconnectedByServer,
    );
  }
}
