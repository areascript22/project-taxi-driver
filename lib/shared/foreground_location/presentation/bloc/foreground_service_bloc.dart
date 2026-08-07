import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../service/driver_foreground_service.dart';

part 'foreground_service_event.dart';
part 'foreground_service_state.dart';

// Bloc del toggle manual de "Peticiones Entrantes": solo prueba que el
// foreground service (y su notificación persistente) prende y apaga bien.
// No pasa passengerId -- ese modo lo maneja TripBloc cuando hay un viaje real.
class ForegroundServiceBloc
    extends Bloc<ForegroundServiceEvent, ForegroundServiceState> {
  final DriverForegroundService driverForegroundService;

  ForegroundServiceBloc({required this.driverForegroundService})
    : super(const ForegroundServiceState()) {
    on<ForegroundServiceStatusRequested>(_onStatusRequested);
    on<ForegroundServiceToggled>(_onToggled);
  }

  Future<void> _onStatusRequested(
    ForegroundServiceStatusRequested event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    // No asumimos "apagado" por defecto: si el servicio ya venía corriendo
    // (por ejemplo, un viaje activo antes de volver a esta pantalla) el
    // toggle debe reflejar eso, no forzar un falso "desactivado".
    final isRunning = await driverForegroundService.isRunning();
    emit(state.copyWith(isRunning: isRunning));
  }

  Future<void> _onToggled(
    ForegroundServiceToggled event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));

    if (state.isRunning) {
      await driverForegroundService.stop();
    } else {
      await driverForegroundService.start();
    }

    final isRunning = await driverForegroundService.isRunning();
    emit(state.copyWith(isRunning: isRunning, isProcessing: false));
  }
}
