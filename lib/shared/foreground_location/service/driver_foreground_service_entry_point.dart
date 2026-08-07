import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../../feature/trip/data/repository/trip_repository_impl.dart';
import '../../../feature/trip/domain/repository/trip_repository.dart';
import '../../geolocator/service/geolocator/geolocator_service.dart';
import '../../geolocator/service/geolocator/geolocator_service_impl.dart';

const _trackingInterval = Duration(seconds: 5);

// Punto de entrada del isolate en el que corre el foreground service.
//
// Este isolate NO comparte memoria con el isolate principal de la app: no
// tiene acceso a GetIt.instance ni a nada registrado en main(), aunque en
// Android corra en el mismo proceso. Por eso, en vez de reusar el service
// locator de la app, se instancian directamente las únicas dos piezas que
// este isolate necesita -- mantiene la dependencia mínima y evita arrastrar
// aquí DI de features (auth, voz, etc.) que no tienen nada que ver con
// reportar ubicación.
@pragma('vm:entry-point')
void driverForegroundServiceEntryPoint(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  final GeolocatorService geolocatorService = GeolocatorServiceServiceImpl();
  final TripRepository tripRepository = TripRepositoryImpl();

  Timer? locationTimer;

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

  service.on('stopService').listen((event) {
    locationTimer?.cancel();
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
bool driverForegroundServiceOnIosBackground(ServiceInstance service) {
  return true;
}
