part of 'foreground_service_bloc.dart';

@immutable
class ForegroundServiceState {
  final bool isRunning;
  // true mientras se está iniciando/deteniendo -- deshabilita el switch para
  // evitar togglear dos veces mientras el plugin nativo responde.
  final bool isProcessing;

  const ForegroundServiceState({
    this.isRunning = false,
    this.isProcessing = false,
  });

  ForegroundServiceState copyWith({bool? isRunning, bool? isProcessing}) {
    return ForegroundServiceState(
      isRunning: isRunning ?? this.isRunning,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
