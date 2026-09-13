  import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../../../feature/incoming_request/domain/entity/incoming_request_entity.dart';
import '../../../feature/trip/data/repository/trip_repository_impl.dart';
import '../../../feature/trip/domain/repository/trip_repository.dart';
import '../../domain/entity/user_location.dart';
import '../../feature/settings/data/repository/settings_repository_impl.dart';
import '../../feedback/feedback_service.dart';
import '../../feedback/feedback_service_impl.dart';
import '../../geolocator/service/geolocator/geolocator_service.dart';
import '../../geolocator/service/geolocator/geolocator_service_impl.dart';
import '../../vibration/service/vibration_service_impl.dart';
import '../../voice/service/voice_service_impl.dart';

const _trackingInterval = Duration(seconds: 5);
// El GPS de celular tiene ruido de varios metros incluso parado -- sin este
// piso, cada tick de 5s reescribiría Firebase aunque el conductor no se
// haya movido, generando tráfico/costos innecesarios.
const _minMovementMeters = 5.0;

// Punto de entrada del isolate en el que corre el foreground service.
//
// Este isolate NO comparte memoria con el isolate principal de la app: no
// tiene acceso a GetIt.instance ni a nada registrado en main(), aunque en
// Android corra en el mismo proceso. Por eso, en vez de reusar el service
// locator de la app, se instancian directamente las piezas que este isolate
// necesita (reporte de ubicación + alerta de nuevas carreras) -- mantiene la
// dependencia mínima y evita arrastrar aquí DI de features (auth, etc.) que
// no tienen nada que ver con esto.
@pragma('vm:entry-point')
void driverForegroundServiceEntryPoint(ServiceInstance service) async {
  debugPrint('ForegroundLocationDebug | Entry point del isolate arrancando...');
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint('ForegroundLocationDebug | Firebase.initializeApp() completado en el isolate');

  final GeolocatorService geolocatorService = GeolocatorServiceServiceImpl();
  final TripRepository tripRepository = TripRepositoryImpl();
  final FeedbackService feedbackService = FeedbackServiceImpl(
    settingsRepository: SettingsRepositoryImpl(),
    voiceService: VoiceServiceImpl(),
    vibrationService: VibrationServiceImpl(),
  );

  Timer? locationTimer;
  StreamSubscription<DatabaseEvent>? newRequestAddedSub;
  StreamSubscription<DatabaseEvent>? newRequestRemovedSub;
  // Última posición efectivamente escrita en Firebase (no la última leída
  // del GPS) -- se resetea a null cada vez que arranca un tracking nuevo,
  // así el primer reporte de cada viaje siempre se escribe sin importar el
  // filtro de movimiento mínimo.
  UserLocation? lastReportedLocation;

  Future<void> reportCurrentLocation(String passengerId) async {
    debugPrint(
      'ForegroundLocationDebug | Checking for location update... (passengerId=$passengerId)',
    );
    try {
      final result = await geolocatorService.getCurrentPosition();
      await result.fold(
        (failure) async {
          debugPrint(
            'ForegroundLocationDebug | getCurrentPosition() falló: ${failure.message}',
          );
        },
        (location) async {
          debugPrint(
            'ForegroundLocationDebug | Posición leída: '
            '(${location.latitude}, ${location.longitude})',
          );

          final last = lastReportedLocation;
          if (last != null) {
            final movedMeters = Geolocator.distanceBetween(
              last.latitude,
              last.longitude,
              location.latitude,
              location.longitude,
            );
            if (movedMeters < _minMovementMeters) {
              debugPrint(
                'ForegroundLocationDebug | Descartado por movimiento mínimo '
                '(${movedMeters.toStringAsFixed(2)}m < ${_minMovementMeters}m)',
              );
              return;
            }
          }

          lastReportedLocation = location;
          final updateResult = await tripRepository.updateDriverLocation(
            passengerId: passengerId,
            latitude: location.latitude,
            longitude: location.longitude,
          );
          updateResult.fold(
            (failure) => debugPrint(
              'ForegroundLocationDebug | updateDriverLocation() falló: ${failure.message}',
            ),
            (_) => debugPrint(
              'ForegroundLocationDebug | updateDriverLocation() OK para passengerId=$passengerId',
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('ForegroundLocationDebug | Excepción inesperada en reportCurrentLocation: $e');
    }
  }

  // 'track' llega tanto para arrancar el tracking de un viaje (passengerId
  // presente) como para pasar a modo de prueba (passengerId nulo): en ambos
  // casos primero se cancela cualquier timer anterior para no terminar con
  // dos loops escribiendo ubicación a la vez.
  service.on('track').listen((event) {
    try {
      debugPrint('ForegroundLocationDebug | Evento "track" recibido: $event');
      locationTimer?.cancel();
      lastReportedLocation = null;
      final passengerId = event?['passengerId'] as String?;
      if (passengerId == null) {
        debugPrint(
          'ForegroundLocationDebug | passengerId nulo -- modo de prueba, sin tracking',
        );
        return;
      }

      locationTimer = Timer.periodic(
        _trackingInterval,
        (_) => reportCurrentLocation(passengerId),
      );
      debugPrint(
        'ForegroundLocationDebug | Timer de tracking creado para passengerId=$passengerId',
      );
    } catch (e) {
      debugPrint('ForegroundLocationDebug | Excepción manejando evento "track": $e');
    }
  });

  // Alerta de "Nueva carrera" (voz + vibración): corre siempre que el
  // servicio esté vivo (conductor "online"), sin depender de 'track', para
  // que suene incluso con la app en background o killed. Es la ÚNICA fuente
  // de esta alerta -- IncomingRequestBloc (isolate principal) solo actualiza
  // la lista visualmente, para no duplicar el sonido cuando la app está en
  // foreground.
  final pendingQuery = FirebaseDatabase.instance
      .ref('taxi_requests')
      .orderByChild('status')
      .equalTo('pending');
  final Set<String> knownPendingIds = {};

  Future<void> startNewRequestAlerts() async {
    try {
      // Puebla el set con los ids que YA existen antes de suscribirse --
      // onChildAdded dispara retroactivamente por cada hijo ya presente, y
      // no queremos alertar por carreras que no son nuevas.
      //
      // Sin orderByChild/equalTo a propósito: esa query puntual (.get())
      // requiere un ".indexOn": "status" declarado en las reglas de
      // Firebase para /taxi_requests, y sin él el servidor la rechaza con
      // una excepción dura (a diferencia de pendingQuery.onChildAdded más
      // abajo, que es streaming y solo emite un warning si falta el
      // índice). Traer el nodo completo y filtrar en Dart evita depender
      // de que ese índice esté configurado.
      final snapshot = await FirebaseDatabase.instance.ref('taxi_requests').get();
      final rawValue = snapshot.value;
      if (rawValue != null) {
        final allRequests = Map<dynamic, dynamic>.from(rawValue as Map);
        allRequests.forEach((id, data) {
          final status = data is Map ? data['status'] : null;
          if (status == 'pending') knownPendingIds.add(id.toString());
        });
      }
    } catch (_) {
      // Sin conectividad al arrancar: seguimos igual -- mejor un falso
      // positivo en el primer onChildAdded que quedarse mudo.
    }

    newRequestAddedSub = pendingQuery.onChildAdded.listen((event) {
      final id = event.snapshot.key;
      if (id == null || knownPendingIds.contains(id)) return;
      knownPendingIds.add(id);

      // Mismo parseo que usa IncomingRequestBloc en el isolate principal
      // (IncomingRequestEntity.fromMap) -- así el mensaje hablado usa
      // exactamente la misma dirección que se ve en la lista.
      final rawValue = event.snapshot.value;
      final address =
          rawValue is Map
              ? IncomingRequestEntity.fromMap(rawValue).pickupLocation.address
              : '';

      feedbackService.announce(
        address.isNotEmpty ? 'Carrera hacia $address' : 'Nueva carrera',
        withVibration: true,
      );
    });

    // El nodo se indexa por passengerId, no por rideId: un mismo pasajero
    // puede volver a estar 'pending' en un viaje posterior reutilizando la
    // misma key. Sin liberar el id acá, esa segunda carrera nunca alertaría.
    newRequestRemovedSub = pendingQuery.onChildRemoved.listen((event) {
      final id = event.snapshot.key;
      if (id != null) knownPendingIds.remove(id);
    });
  }

  startNewRequestAlerts();

  service.on('stopService').listen((event) {
    debugPrint('ForegroundLocationDebug | Evento "stopService" recibido');
    locationTimer?.cancel();
    newRequestAddedSub?.cancel();
    newRequestRemovedSub?.cancel();
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
bool driverForegroundServiceOnIosBackground(ServiceInstance service) {
  return true;
}
