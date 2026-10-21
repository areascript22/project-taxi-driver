import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../../../../core/error/errors.dart';
import '../../../battery_optimization/service/battery_optimization_service.dart';
import '../../../geolocator/service/geolocator/geolocator_service.dart';
import '../../../presence/domain/repository/driver_presence_repository.dart';
import '../../service/driver_foreground_service.dart';

part 'foreground_service_event.dart';
part 'foreground_service_state.dart';

// Bloc del toggle "online/offline" de "Peticiones Entrantes": controla si el
// conductor recibe carreras nuevas (IncomingRequestScreen se suscribe/
// desuscribe de su bandeja de ofertas según state.isRunning). No pasa
// passengerId -- ese modo lo maneja TripBloc cuando hay un viaje real.
//
// "En línea" es una decisión del SERVIDOR, no solo de la app: ponerse en línea
// exige estar aprobado y no bloqueado, y es lo que hace que el despacho le
// ofrezca carreras. Por eso encender primero le pregunta al servidor y solo
// arranca el servicio (que reporta la ubicación) si lo acepta.
//
// Por la misma razón el SERVIDOR es la fuente de verdad del interruptor: al
// entrar y al volver de segundo plano (ForegroundServiceStatusRequested) se lee
// `driver.online` de /api/me y se reconcilia con el servicio local. Mirar solo
// si el servicio de Android sigue vivo dejaba el switch "encendido" mientras la
// base decía "apagado" (el apagado real del servicio tarda unos segundos, y el
// bloc se recrea en cada visita a la pantalla).
//
// Y no se conecta a quien no tiene ubicación: estar "en línea" sin ella es no
// recibir pedidos en silencio. Antes de conectar se prueba el GPS, y mientras
// el servicio corre avisa si lo pierde (ver locationIssue en el estado).
//
// Encender el toggle además exige el permiso de "ignorar optimización de
// batería" (ver BatteryOptimizationService): sin él, Android puede matar el
// foreground service en cuanto el conductor cierra la app, perdiendo el
// tracking de un viaje en curso.
class ForegroundServiceBloc
    extends Bloc<ForegroundServiceEvent, ForegroundServiceState> {
  final DriverForegroundService driverForegroundService;
  final BatteryOptimizationService batteryOptimizationService;
  final DriverPresenceRepository driverPresenceRepository;
  final GeolocatorService geolocatorService;

  // Lo que se espera a que el GPS dé una posición antes de conectar. Más largo
  // que el de las lecturas periódicas: la primera tras un rato apagado puede
  // tardar en fijar.
  static const _preflightLocationTimeout = Duration(seconds: 15);

  StreamSubscription<FailureCode?>? _locationIssueSub;

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
    required this.driverPresenceRepository,
    required this.geolocatorService,
  }) : super(const ForegroundServiceState()) {
    on<ForegroundServiceStatusRequested>(_onStatusRequested);
    on<ForegroundServiceToggled>(_onToggled);
    on<BatteryOptimizationPermissionRequested>(_onBatteryPermissionRequested);
    on<BatteryOptimizationPromptDismissed>(_onBatteryPromptDismissed);
    on<BatteryOptimizationSettingsOpened>(_onBatterySettingsOpened);
    on<BatteryOptimizationStatusRechecked>(_onBatteryStatusRechecked);
    on<ForegroundServiceLocationIssueChanged>(_onLocationIssueChanged);
    on<LocationSettingsOpened>(_onLocationSettingsOpened);

    _locationIssueSub = driverForegroundService.locationIssue.listen(
      (issue) => add(ForegroundServiceLocationIssueChanged(issue)),
    );
  }

  @override
  Future<void> close() async {
    await _locationIssueSub?.cancel();
    return super.close();
  }

  Future<void> _onStatusRequested(
    ForegroundServiceStatusRequested event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    // Una conexión o desconexión en curso decide ella misma cómo termina:
    // reconciliar en medio leería al servidor a medio cambiar.
    if (state.isProcessing) return;

    // Lo que dice el servicio de Android de ESTE teléfono. No alcanza: puede
    // seguir vivo mientras se apaga, o haber muerto sin avisar.
    var isRunning = await driverForegroundService.isRunning();

    final batteryResult =
        await batteryOptimizationService.isIgnoringBatteryOptimizations();
    final isBatteryOptimizationIgnored = batteryResult.fold((failure) {
      debugPrint(
        'ForegroundLocationDebug | No se pudo consultar optimización de batería: ${failure.code}',
      );
      return false;
    }, (granted) => granted);

    // Lo que dice el SERVIDOR (drivers.is_online), que es lo que usa el
    // despacho. Si no se le puede consultar, no se adivina: se queda con lo
    // local, y la siguiente vez que se abra o se vuelva de segundo plano se
    // reconcilia.
    var disconnectedByServer = false;
    final serverResult = await driverPresenceRepository.fetchOnline();
    await serverResult.fold<Future<void>>(
      (failure) async {
        debugPrint(
          'ForegroundLocationDebug | No se pudo consultar el estado al servidor '
          '(${failure.code}): se usa el estado local',
        );
      },
      (serverOnline) async {
        if (isRunning && !serverOnline) {
          // El servidor manda: lo tiene fuera de línea (apagó él mismo, lo
          // bloquearon, se recreó la base...). Seguir "encendido" aquí solo
          // reportaría ubicación a quien no la va a usar, con un switch
          // mintiendo.
          debugPrint(
            'ForegroundLocationDebug | El servidor lo tiene FUERA de línea pero el servicio corre: se detiene',
          );
          await driverForegroundService.stop();
          isRunning = false;
          disconnectedByServer = true;
        } else if (!isRunning && serverOnline) {
          // El servidor lo tiene EN línea pero el servicio no corre (Android lo
          // mató, el teléfono se reinició). La intención del conductor era
          // estar conectado: se retoma si se puede. Sin el permiso de batería
          // no se podría sostener, y entonces se deja todo apagado.
          if (isBatteryOptimizationIgnored) {
            debugPrint(
              'ForegroundLocationDebug | El servidor lo tiene EN línea pero el servicio no corre: se reanuda',
            );
            await driverForegroundService.start();
            isRunning = true;
          } else {
            debugPrint(
              'ForegroundLocationDebug | El servidor lo tiene EN línea pero no se puede reanudar el servicio: se le avisa "fuera de línea"',
            );
            await driverPresenceRepository.setOnline(online: false);
          }
        }
      },
    );

    // Mientras se reconciliaba pudo empezar una conexión o desconexión: ella
    // tiene la última palabra.
    if (state.isProcessing) return;

    debugPrint(
      'ForegroundLocationDebug | Status inicial -> isRunning=$isRunning, '
      'isBatteryOptimizationIgnored=$isBatteryOptimizationIgnored',
    );

    emit(
      state.copyWith(
        isRunning: isRunning,
        hasLoadedStatus: true,
        isBatteryOptimizationIgnored: isBatteryOptimizationIgnored,
        disconnectedByServer: disconnectedByServer,
        // Un problema de ubicación de una conexión anterior ya no aplica si no
        // está conectado: se vuelve a comprobar al intentar conectarse.
        clearLocationIssue: !isRunning,
      ),
    );

    // La pantalla se recrea al entrar y no vería un problema de ubicación que ya
    // empezó: se le pide al servicio que lo repita.
    if (isRunning) await driverForegroundService.requestLocationStatus();
  }

  Future<void> _onToggled(
    ForegroundServiceToggled event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    final shouldRun = !state.isRunning;

    // Apagar nunca requiere el permiso de batería.
    if (!shouldRun) {
      emit(state.copyWith(isProcessing: true));
      // Primero se le avisa al servidor, para que deje de ofrecerle carreras
      // aunque detener el servicio falle. Es best-effort: apagar nunca se
      // bloquea por un fallo de red (si el servidor no se entera, la
      // ubicación deja de llegar y por frescura sale solo del despacho).
      final offline = await driverPresenceRepository.setOnline(online: false);
      offline.fold(
        (failure) => debugPrint(
          'ForegroundLocationDebug | No se pudo avisar "fuera de línea": ${failure.code}',
        ),
        (_) {},
      );
      await driverForegroundService.stop();
      emit(
        state.copyWith(
          isRunning: false,
          isProcessing: false,
          hasLoadedStatus: true,
          clearLocationIssue: true,
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
        'ForegroundLocationDebug | Error solicitando permiso de batería: ${failure.code}',
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
    emit(state.copyWith(batteryPromptStep: BatteryOptimizationPromptStep.none));
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
          'ForegroundLocationDebug | Error en poll de batería (intento $attempt/$maxAttempts): ${failure.code}',
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

    // Sin ubicación utilizable no tiene sentido ponerse en línea: el servidor
    // descarta posiciones de más de 45 s y el conductor no recibiría pedidos
    // sin que nada se lo dijera. Se prueba el GPS ANTES de avisar al servidor.
    final located = await geolocatorService.getCurrentPosition(
      timeLimit: _preflightLocationTimeout,
    );
    final locationFailure = located.fold<FailureCode?>(
      (failure) =>
          failure.code == FailureCode.unexpected
              ? FailureCode.locationUnavailable
              : failure.code,
      (_) => null,
    );
    if (locationFailure != null) {
      debugPrint(
        'ForegroundLocationDebug | Sin ubicación utilizable, no se conecta: $locationFailure',
      );
      emit(
        state.copyWith(
          isRunning: false,
          isProcessing: false,
          hasLoadedStatus: true,
          batteryPromptStep: BatteryOptimizationPromptStep.none,
          errorCode: locationFailure,
          locationIssue: locationFailure,
        ),
      );
      return;
    }

    // El servidor decide si puede estar en línea (aprobado, no bloqueado,
    // perfil listo). Si dice que no, el servicio ni arranca: no tiene sentido
    // reportar una ubicación que nadie va a usar.
    final online = await driverPresenceRepository.setOnline(online: true);
    final rejected = online.fold<FailureCode?>(
      (failure) => failure.code,
      (_) => null,
    );
    if (rejected != null) {
      debugPrint(
        'ForegroundLocationDebug | El servidor rechazó ponerse en línea: $rejected',
      );
      emit(
        state.copyWith(
          isRunning: false,
          isProcessing: false,
          hasLoadedStatus: true,
          batteryPromptStep: BatteryOptimizationPromptStep.none,
          errorCode: rejected,
          clearLocationIssue: true,
        ),
      );
      return;
    }

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
        clearLocationIssue: true,
      ),
    );
  }

  Future<void> _onLocationIssueChanged(
    ForegroundServiceLocationIssueChanged event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    // Avisos tardíos de un servicio que ya se está apagando no cuentan: el
    // conductor ya no está en línea.
    if (!state.isRunning) return;
    if (state.locationIssue == event.issue) return;

    emit(
      state.copyWith(
        locationIssue: event.issue,
        clearLocationIssue: event.issue == null,
      ),
    );
  }

  Future<void> _onLocationSettingsOpened(
    LocationSettingsOpened event,
    Emitter<ForegroundServiceState> emit,
  ) async {
    // Con el permiso denegado no sirve abrir los ajustes de ubicación del
    // dispositivo: el cambio hay que hacerlo en los permisos de la app.
    if (state.locationIssue == FailureCode.locationPermissionDenied) {
      await geolocatorService.openAppSettings();
      return;
    }
    await geolocatorService.openLocationSettings();
  }
}
