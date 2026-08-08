  import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../../feature/trip/data/repository/trip_repository_impl.dart';
import '../../../feature/trip/domain/repository/trip_repository.dart';
import '../../feature/settings/data/repository/settings_repository_impl.dart';
import '../../feedback/feedback_service.dart';
import '../../feedback/feedback_service_impl.dart';
import '../../geolocator/service/geolocator/geolocator_service.dart';
import '../../geolocator/service/geolocator/geolocator_service_impl.dart';
import '../../vibration/service/vibration_service_impl.dart';
import '../../voice/service/voice_service_impl.dart';

const _trackingInterval = Duration(seconds: 5);

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
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

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

  Future<void> reportCurrentLocation(String passengerId) async {
    final result = await geolocatorService.getCurrentPosition();
    await result.fold((_) async {}, (location) {
      return tripRepository.updateDriverLocation(
        passengerId: passengerId,
        latitude: location.latitude,
        longitude: location.longitude,
      );
    });
  }

  // 'track' llega tanto para arrancar el tracking de un viaje (passengerId
  // presente) como para pasar a modo de prueba (passengerId nulo): en ambos
  // casos primero se cancela cualquier timer anterior para no terminar con
  // dos loops escribiendo ubicación a la vez.
  service.on('track').listen((event) {
    locationTimer?.cancel();
    final passengerId = event?['passengerId'] as String?;
    if (passengerId == null) return;

    locationTimer = Timer.periodic(
      _trackingInterval,
      (_) => reportCurrentLocation(passengerId),
    );
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
      final snapshot = await pendingQuery.get();
      for (final child in snapshot.children) {
        final id = child.key;
        if (id != null) knownPendingIds.add(id);
      }
    } catch (_) {
      // Sin conectividad al arrancar: seguimos igual -- mejor un falso
      // positivo en el primer onChildAdded que quedarse mudo.
    }

    newRequestAddedSub = pendingQuery.onChildAdded.listen((event) {
      final id = event.snapshot.key;
      if (id == null || knownPendingIds.contains(id)) return;
      knownPendingIds.add(id);
      feedbackService.announce('Nueva carrera', withVibration: true);
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
