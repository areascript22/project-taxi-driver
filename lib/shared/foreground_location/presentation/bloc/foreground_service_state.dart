part of 'foreground_service_bloc.dart';

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

  const ForegroundServiceState({
    this.isRunning = false,
    this.isProcessing = false,
    this.hasLoadedStatus = false,
  });

  ForegroundServiceState copyWith({
    bool? isRunning,
    bool? isProcessing,
    bool? hasLoadedStatus,
  }) {
    return ForegroundServiceState(
      isRunning: isRunning ?? this.isRunning,
      isProcessing: isProcessing ?? this.isProcessing,
      hasLoadedStatus: hasLoadedStatus ?? this.hasLoadedStatus,
    );
  }
}
