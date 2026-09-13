import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../../../battery_optimization/service/battery_optimization_service.dart';
import '../../service/driver_foreground_service.dart';

part 'foreground_service_event.dart';
part 'foreground_service_state.dart';

// Bloc del toggle "online/offline" de "Peticiones Entrantes": controla si el
// conductor recibe carreras nuevas (IncomingRequestScreen se suscribe/
// desuscribe de Firebase según state.isRunning). No pasa passengerId -- ese
// modo lo maneja TripBloc cuando hay un viaje real.
//
// Encender el toggle además exige el permiso de "ignorar optimización de
// batería" (ver BatteryOptimizationService): sin él, Android puede matar el
// foreground service en cuanto el conductor cierra la app, perdiendo el
// tracking de un viaje en curso.
class ForegroundServiceBloc
    extends Bloc<ForegroundServiceEvent, ForegroundServiceState> {
  final DriverForegroundService driverForegroundService;
  final BatteryOptimizationService batteryOptimizationService;

  // Token del poll de batería en curso. Si dos polls quedan corriendo a la
  // vez (p.ej. dos resumes seguidos, o un resume mientras el usuario ya
  // había tocado "Reintentar"), solo el resultado del último invocado puede
  // emitir -- evita que un poll viejo y lento pise con "false" el resultado
  // ya confirmado de uno más nuevo.
  int _batteryPollToken = 0;

  // true cuando el conductor tocó el toggle para ir online pero quedó
  // bloqueado esperando el permiso de batería. Cualquiera de los dos polls
  // (el del request directo o el silencioso del resume) puede terminar
  // confirmando el permiso -- el que lo confirme primero es quien debe
  // arrancar el servicio, sin importar cuál de los dos lo originó. Se
  // limpia al consumirlo o si el usuario descarta el diálogo explicativo.
  bool _pendingGoOnline = false;

  ForegroundServiceBloc({
    required this.driverForegroundService,
    required this.batteryOptimizationService,
  }) : super(const ForegroundServiceState()) {
    on<ForegroundServiceStatusRequested>(_onStatusRequested);
    on<ForegroundServiceToggled>(_onToggled);
    on<BatteryOptimizationPermissionRequested>(_onBatteryPermissionRequested);
    on<BatteryOptimizationPromptDismissed>(_onBatteryPromptDismissed);
    on<BatteryOptimizationSettingsOpened>(_onBatterySettingsOpened);
    on<BatteryOptimizationStatusRechecked>(_onBatteryStatusRechecked);
  }

  Future<void> _onStatusRequested(
    ForegroundServiceStatusRequested event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    // No asumimos "apagado" por defecto: si el servicio ya venía corriendo
    // (por ejemplo, un viaje activo antes de volver a esta pantalla) el
    // toggle debe reflejar eso, no forzar un falso "desactivado".
    final isRunning = await driverForegroundService.isRunning();

    final batteryResult =
        await batteryOptimizationService.isIgnoringBatteryOptimizations();
    final isBatteryOptimizationIgnored = batteryResult.fold((failure) {
      debugPrint(
        'ForegroundLocationDebug | No se pudo consultar optimización de batería: ${failure.message}',
      );
      return false;
    }, (granted) => granted);

    debugPrint(
      'ForegroundLocationDebug | Status inicial -> isRunning=$isRunning, '
      'isBatteryOptimizationIgnored=$isBatteryOptimizationIgnored',
    );

    emit(
      state.copyWith(
        isRunning: isRunning,
        hasLoadedStatus: true,
        isBatteryOptimizationIgnored: isBatteryOptimizationIgnored,
      ),
    );
  }

  Future<void> _onToggled(
    ForegroundServiceToggled event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    final shouldRun = !state.isRunning;

    // Apagar nunca requiere el permiso de batería.
    if (!shouldRun) {
      emit(state.copyWith(isProcessing: true));
      await driverForegroundService.stop();
      emit(
        state.copyWith(
          isRunning: false,
          isProcessing: false,
          hasLoadedStatus: true,
        ),
      );
      return;
    }

    if (!state.isBatteryOptimizationIgnored) {
      debugPrint(
        'ForegroundLocationDebug | Toggle ON bloqueado: falta permiso de optimización de batería',
      );
      _pendingGoOnline = true;
      emit(
        state.copyWith(
          batteryPromptStep: BatteryOptimizationPromptStep.rationale,
        ),
      );
      return;
    }

    await _startService(emit);
  }

  Future<void> _onBatteryPermissionRequested(
    BatteryOptimizationPermissionRequested event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    emit(
      state.copyWith(
        isProcessing: true,
        batteryPromptStep: BatteryOptimizationPromptStep.none,
      ),
    );

    final result =
        await batteryOptimizationService.requestIgnoreBatteryOptimizations();
    var granted = result.fold((failure) {
      debugPrint(
        'ForegroundLocationDebug | Error solicitando permiso de batería: ${failure.message}',
      );
      return false;
    }, (granted) => granted);

    debugPrint(
      'ForegroundLocationDebug | Permiso de batería (respuesta inmediata) -> $granted',
    );

    var pollToken = _batteryPollToken;
    if (!granted) {
      // En varios OEMs (MIUI "Batería y Rendimiento", por ejemplo) el
      // diálogo nativo redirige a su propia pantalla de Ajustes y el
      // Future de request() se resuelve "denegado" en cuanto ocurre esa
      // redirección -- no cuando el usuario termina de interactuar con esa
      // pantalla y vuelve. Antes de darnos por vencidos, confirmamos con el
      // mismo poll acotado que usa el recheck de resume.
      pollToken = ++_batteryPollToken;
      granted = await _pollBatteryOptimizationGranted(pollToken);
    }

    // Un poll más nuevo (otro request o un recheck de resume) ya resolvió
    // esto -- no pisar su resultado con el nuestro, que quedó obsoleto.
    if (pollToken != _batteryPollToken) return;

    if (!granted) {
      emit(
        state.copyWith(
          isProcessing: false,
          isBatteryOptimizationIgnored: false,
          batteryPromptStep: BatteryOptimizationPromptStep.deniedBanner,
        ),
      );
      return;
    }

    emit(state.copyWith(isBatteryOptimizationIgnored: true));
    _pendingGoOnline = false;
    await _startService(emit);
  }

  Future<void> _onBatteryPromptDismissed(
    BatteryOptimizationPromptDismissed event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    debugPrint(
      'ForegroundLocationDebug | Diálogo explicativo de batería descartado por el usuario',
    );
    // El conductor eligió "Ahora no" -- ya no hay que conectarlo solo si el
    // permiso termina apareciendo concedido más tarde por otra vía.
    _pendingGoOnline = false;
    emit(
      state.copyWith(batteryPromptStep: BatteryOptimizationPromptStep.none),
    );
  }

  Future<void> _onBatterySettingsOpened(
    BatteryOptimizationSettingsOpened event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    await batteryOptimizationService.openAppSettings();
  }

  Future<void> _onBatteryStatusRechecked(
    BatteryOptimizationStatusRechecked event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    // Ya sabíamos que estaba concedido -- revocarlo manualmente desde
    // Ajustes sí se refleja de forma síncrona, así que no hace falta
    // reintentar acá; si de verdad lo revocó, el próximo intento de
    // encender el toggle lo va a detectar igual.
    if (state.isBatteryOptimizationIgnored) return;

    final pollToken = ++_batteryPollToken;
    final granted = await _pollBatteryOptimizationGranted(pollToken);

    if (pollToken != _batteryPollToken) return;
    if (granted == state.isBatteryOptimizationIgnored) return;

    if (granted && _pendingGoOnline) {
      // El conductor ya había tocado el toggle antes de irse a Ajustes --
      // retomamos esa intención acá en vez de dejarlo "desbloqueado pero
      // offline" esperando un segundo tap manual.
      debugPrint(
        'ForegroundLocationDebug | Permiso confirmado por recheck de resume -- retomando intención de ir online',
      );
      _pendingGoOnline = false;
      emit(state.copyWith(isBatteryOptimizationIgnored: true));
      await _startService(emit);
      return;
    }

    // Si ahora SÍ está concedido y había un banner/diálogo de bloqueo
    // pendiente, se limpia solo -- el usuario no tiene que tocar
    // "Reintentar" a mano.
    emit(
      state.copyWith(
        isBatteryOptimizationIgnored: granted,
        batteryPromptStep:
            granted
                ? BatteryOptimizationPromptStep.none
                : state.batteryPromptStep,
      ),
    );
  }

  // Reintenta consultar el permiso de batería con espera acotada (hasta
  // ~10s). Necesario porque en varios OEMs (MIUI "Batería y Rendimiento",
  // por ejemplo) el cambio hecho en su propia pantalla de Ajustes no se
  // propaga de forma síncrona al PowerManager real de Android -- la
  // reconciliación interna corre en background y, en dispositivos con
  // carga alta, puede tardar varios segundos en reflejarse. Corta apenas
  // detecta `true`, o si un poll más nuevo lo superó (ver `_batteryPollToken`).
  Future<bool> _pollBatteryOptimizationGranted(int token) async {
    const maxAttempts = 8;
    const interval = Duration(milliseconds: 1200);
    var granted = false;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (token != _batteryPollToken) {
        debugPrint(
          'ForegroundLocationDebug | Poll de batería cancelado (superado por uno más nuevo)',
        );
        return false;
      }

      final result =
          await batteryOptimizationService.isIgnoringBatteryOptimizations();
      granted = result.fold((failure) {
        debugPrint(
          'ForegroundLocationDebug | Error en poll de batería (intento $attempt/$maxAttempts): ${failure.message}',
        );
        return false;
      }, (value) => value);

      debugPrint(
        'ForegroundLocationDebug | Poll de batería intento $attempt/$maxAttempts -> $granted',
      );

      if (granted) break;
      if (attempt < maxAttempts) await Future.delayed(interval);
    }

    return granted;
  }

  Future<void> _startService(Emitter<ForegroundServiceState> emit) async {
    emit(state.copyWith(isProcessing: true));
    await driverForegroundService.start();

    // A diferencia de start(), stop() solo manda un mensaje fire-and-forget
    // al isolate del servicio (invoke() no espera a que se procese) -- el
    // apagado real tarda unos segundos, igual que tarda en prender. Si acá
    // volviéramos a preguntar isRunning(), casi siempre nos daría "true"
    // todavía y el switch rebotaría a encendido. El estado optimista es el
    // dato correcto en este punto: ya se pidió la acción.
    emit(
      state.copyWith(
        isRunning: true,
        isProcessing: false,
        hasLoadedStatus: true,
        batteryPromptStep: BatteryOptimizationPromptStep.none,
      ),
    );
  }
}
