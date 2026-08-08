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
    final shouldRun = !state.isRunning;
    emit(state.copyWith(isProcessing: true));

    if (shouldRun) {
      await driverForegroundService.start();
    } else {
      await driverForegroundService.stop();
    }

    // A diferencia de start(), stop() solo manda un mensaje fire-and-forget
    // al isolate del servicio (invoke() no espera a que se procese) -- el
    // apagado real tarda unos segundos, igual que tarda en prender. Si acá
    // volviéramos a preguntar isRunning(), casi siempre nos daría "true"
    // todavía y el switch rebotaría a encendido. El estado optimista es el
    // dato correcto en este punto: ya se pidió la acción.
    emit(state.copyWith(isRunning: shouldRun, isProcessing: false));
  }
}
