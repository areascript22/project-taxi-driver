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

  const ForegroundServiceState({
    this.isRunning = false,
    this.isProcessing = false,
    this.hasLoadedStatus = false,
    this.isBatteryOptimizationIgnored = false,
    this.batteryPromptStep = BatteryOptimizationPromptStep.none,
  });

  ForegroundServiceState copyWith({
    bool? isRunning,
    bool? isProcessing,
    bool? hasLoadedStatus,
    bool? isBatteryOptimizationIgnored,
    BatteryOptimizationPromptStep? batteryPromptStep,
  }) {
    return ForegroundServiceState(
      isRunning: isRunning ?? this.isRunning,
      isProcessing: isProcessing ?? this.isProcessing,
      hasLoadedStatus: hasLoadedStatus ?? this.hasLoadedStatus,
      isBatteryOptimizationIgnored:
          isBatteryOptimizationIgnored ?? this.isBatteryOptimizationIgnored,
      batteryPromptStep: batteryPromptStep ?? this.batteryPromptStep,
    );
  }
}
