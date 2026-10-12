import 'dart:async';
import 'dart:ui';
import 'package:driver_app/shared/l10n/isolate_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../../feature/incoming_request/domain/entity/incoming_request_entity.dart';
import '../../domain/entity/user_location.dart';
import '../../feature/settings/data/repository/settings_repository_impl.dart';
import '../../feedback/feedback_service.dart';
import '../../feedback/feedback_service_impl.dart';
import '../../geolocator/service/geolocator/geolocator_service.dart';
import '../../geolocator/service/geolocator/geolocator_service_impl.dart';
import '../../presence/data/repository/driver_presence_repository_impl.dart';
import '../../services/dotenv/dotenv_service_impl.dart';
import '../../presence/domain/repository/driver_presence_repository.dart';
import '../../utils/pickup_label.dart';
import '../../vibration/service/vibration_service_impl.dart';
import '../../voice/service/voice_service_impl.dart';
import '../domain/location_report_policy.dart';

// Cada cuanto se LEE el GPS. Que ese valor se envie o no al servidor lo decide
// LocationReportPolicy (movimiento minimo o "latido").
const _trackingInterval = Duration(seconds: 5);
const _reportPolicy = LocationReportPolicy();

// Punto de entrada del isolate en el que corre el foreground service.
//
// Este isolate NO comparte memoria con el isolate principal de la app: no
// tiene acceso a GetIt.instance ni a nada registrado en main(), aunque en
// Android corra en el mismo proceso. Por eso, en vez de reusar el service
// locator de la app, se instancian directamente las piezas que este isolate
// necesita (reporte de ubicación + alerta de nuevas carreras) -- mantiene la
// dependencia mínima y evita arrastrar aquí DI de features (auth, etc.) que
// no tienen nada que ver con esto.
//
// Mientras el servicio vive el conductor está "online", y el servicio hace dos
// cosas, ambas hacia/desde el SERVIDOR (la app no escribe en Firebase):
//   1. Reporta la ubicación. Sin carrera, el servidor la usa para el despacho;
//      con carrera (passengerId) la publica para el mapa del pasajero.
//   2. Escucha SU bandeja de ofertas y avisa por voz/vibración.
@pragma('vm:entry-point')
void driverForegroundServiceEntryPoint(ServiceInstance service) async {
  debugPrint('ForegroundLocationDebug | Entry point del isolate arrancando...');
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint('ForegroundLocationDebug | Firebase.initializeApp() completado en el isolate');

  // Este isolate NO comparte memoria con el principal: el dotenv que cargó
  // main() no existe acá. Sin esto, DioClient no puede leer BASE_URL y TODO
  // reporte de ubicación falla en silencio (el conductor figura "en línea" en
  // el servidor, pero nunca llega una ubicación y el despacho no lo ve).
  try {
    await DotEnvServiceImpl().initialize();
    debugPrint('ForegroundLocationDebug | dotenv cargado en el isolate');
  } catch (e) {
    debugPrint('ForegroundLocationDebug | No se pudo cargar dotenv en el isolate: $e');
  }

  final GeolocatorService geolocatorService = GeolocatorServiceServiceImpl();
  final DriverPresenceRepository presenceRepository =
      DriverPresenceRepositoryImpl();
  final settingsRepository = SettingsRepositoryImpl();
  final FeedbackService feedbackService = FeedbackServiceImpl(
    settingsRepository: settingsRepository,
    voiceService: VoiceServiceImpl(settingsRepository: settingsRepository),
    vibrationService: VibrationServiceImpl(),
  );

  Timer? locationTimer;
  StreamSubscription<DatabaseEvent>? newOfferAddedSub;
  StreamSubscription<DatabaseEvent>? newOfferRemovedSub;

  // La carrera en la que va el conductor, o null si está libre. Lo fija el
  // evento 'track'; el servidor decide a dónde va la ubicación según esto.
  String? currentPassengerId;

  // Última posición efectivamente ENVIADA (no la última leída del GPS) y
  // cuándo. Se resetea cada vez que cambia el modo, así el primer reporte de
  // cada modo siempre se envía.
  UserLocation? lastReportedLocation;
  DateTime? lastReportedAt;

  Future<void> reportCurrentLocation() async {
    final passengerId = currentPassengerId;
    try {
      final result = await geolocatorService.getCurrentPosition();
      await result.fold(
        (failure) async {
          debugPrint(
            'ForegroundLocationDebug | getCurrentPosition() falló: ${failure.code}',
          );
        },
        (location) async {
          final last = lastReportedLocation;
          final lastAt = lastReportedAt;
          final shouldReport = _reportPolicy.shouldReport(
            movedMeters:
                last == null
                    ? null
                    : Geolocator.distanceBetween(
                      last.latitude,
                      last.longitude,
                      location.latitude,
                      location.longitude,
                    ),
            sinceLastReport:
                lastAt == null ? null : DateTime.now().difference(lastAt),
          );
          if (!shouldReport) return;

          lastReportedLocation = location;
          lastReportedAt = DateTime.now();
          final reported = await presenceRepository.reportLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            passengerId: passengerId,
          );
          reported.fold(
            (failure) => debugPrint(
              'ForegroundLocationDebug | reportLocation() falló: '
              '${failure.code} (${failure.detail})',
            ),
            (_) => debugPrint(
              'ForegroundLocationDebug | reportLocation() OK '
              '(passengerId=$passengerId)',
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('ForegroundLocationDebug | Excepción inesperada en reportCurrentLocation: $e');
    }
  }

  // El timer corre siempre que el servicio esté vivo: sin carrera reporta para
  // el despacho, con carrera para el mapa del pasajero.
  locationTimer = Timer.periodic(_trackingInterval, (_) => reportCurrentLocation());

  // 'track' llega para pasar a modo carrera (passengerId presente) o volver a
  // modo libre (passengerId nulo). El timer NO se reinicia: solo cambia a
  // dónde va el siguiente reporte, y se fuerza que ese primer reporte salga.
  service.on('track').listen((event) {
    try {
      debugPrint('ForegroundLocationDebug | Evento "track" recibido: $event');
      currentPassengerId = event?['passengerId'] as String?;
      lastReportedLocation = null;
      lastReportedAt = null;
      reportCurrentLocation();
    } catch (e) {
      debugPrint('ForegroundLocationDebug | Excepción manejando evento "track": $e');
    }
  });

  // Alerta de "Nueva carrera" (voz + vibración): corre siempre que el
  // servicio esté vivo (conductor "online"), para que suene incluso con la app
  // en background o killed. Es la ÚNICA fuente de esta alerta --
  // IncomingRequestBloc (isolate principal) solo actualiza la lista
  // visualmente, para no duplicar el sonido cuando la app está en foreground.
  //
  // Escucha SU bandeja de ofertas (driver_offers/{uid}): el despacho solo le
  // deja ahí los pedidos cercanos que le tocan.
  final Set<String> knownOfferIds = {};

  Future<void> startNewOfferAlerts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint(
        'ForegroundLocationDebug | Sin sesión: no se escuchan ofertas',
      );
      return;
    }
    final inbox = FirebaseDatabase.instance.ref('driver_offers/$uid');

    // Este isolate no tiene BuildContext: las traducciones se cargan a mano,
    // una sola vez, antes de suscribirse (el listener de onChildAdded es
    // sincrono y no puede hacer await).
    final isolateL10n = await loadIsolateLocalizations(
      settingsRepository: settingsRepository,
    );

    try {
      // Puebla el set con las ofertas que YA existen antes de suscribirse --
      // onChildAdded dispara retroactivamente por cada hijo ya presente, y no
      // queremos alertar por ofertas que no son nuevas.
      final snapshot = await inbox.get();
      final rawValue = snapshot.value;
      if (rawValue is Map) {
        for (final id in rawValue.keys) {
          knownOfferIds.add(id.toString());
        }
      }
    } catch (_) {
      // Sin conectividad al arrancar: seguimos igual -- mejor un falso
      // positivo en el primer onChildAdded que quedarse mudo.
    }

    newOfferAddedSub = inbox.onChildAdded.listen((event) {
      final id = event.snapshot.key;
      if (id == null || knownOfferIds.contains(id)) return;
      knownOfferIds.add(id);

      final rawValue = event.snapshot.value;
      if (rawValue is! Map) return;
      // Una oferta ya vencida no se anuncia.
      if (IncomingRequestEntity.isOfferExpired(rawValue)) return;

      // Mismo parseo y misma función de etiqueta que usa la lista (tile): el
      // conductor escucha exactamente lo que después ve.
      final pickup = IncomingRequestEntity.fromOffer(rawValue).pickupLocation;
      final label = pickupLabel(sector: pickup.sector, address: pickup.address);

      feedbackService.announce(
        label != null
            ? isolateL10n.isolateRideTowards(label)
            : isolateL10n.commonNewRide,
        withVibration: true,
      );
    });

    // La bandeja se indexa por passengerId: un mismo pasajero puede volver a
    // pedir y reutilizar la misma key. Sin liberar el id acá, esa segunda
    // oferta nunca alertaría.
    newOfferRemovedSub = inbox.onChildRemoved.listen((event) {
      final id = event.snapshot.key;
      if (id != null) knownOfferIds.remove(id);
    });
  }

  startNewOfferAlerts();

  service.on('stopService').listen((event) {
    debugPrint('ForegroundLocationDebug | Evento "stopService" recibido');
    locationTimer?.cancel();
    newOfferAddedSub?.cancel();
    newOfferRemovedSub?.cancel();
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
bool driverForegroundServiceOnIosBackground(ServiceInstance service) {
  return true;
}
