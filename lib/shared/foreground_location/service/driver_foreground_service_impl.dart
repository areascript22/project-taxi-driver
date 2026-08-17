import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'driver_foreground_service.dart';
import 'driver_foreground_service_entry_point.dart';

const _notificationId = 1888;

class DriverForegroundServiceImpl implements DriverForegroundService {
  final FlutterBackgroundService _service;

  DriverForegroundServiceImpl({FlutterBackgroundService? service})
    : _service = service ?? FlutterBackgroundService();

  @override
  Future<void> configure() {
    return _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: driverForegroundServiceEntryPoint,
        autoStart: false,
        isForegroundMode: true,
        // Sin notificationChannelId explícito: el plugin crea y usa su
        // propio canal por defecto ("FOREGROUND_DEFAULT"). Si le pasamos un
        // id custom, el plugin asume que YA existe -- como acá no lo
        // creamos (no agregamos flutter_local_notifications solo para
        // eso), un id custom deja el canal inexistente y Android mata el
        // proceso al llamar startForeground() (RemoteServiceException:
        // "Bad notification for startForeground").
        initialNotificationTitle: 'TaxiGo Conductor',
        initialNotificationContent: 'Reportando tu ubicación...',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: driverForegroundServiceEntryPoint,
        onBackground: driverForegroundServiceOnIosBackground,
      ),
    );
  }

  @override
  Future<void> start({String? passengerId}) async {
    try {
      // Android 13+ exige el permiso runtime para poder mostrar la
      // notificación persistente del servicio. Si el usuario lo niega, el
      // servicio igual arranca y sigue trackeando -- simplemente no se ve.
      await Permission.notification.request();

      if (!await _service.isRunning()) {
        await _service.startService();
      }
      _service.invoke('track', {'passengerId': passengerId});
    } catch (e) {
      debugPrint('No se pudo iniciar el foreground service: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (await _service.isRunning()) {
        _service.invoke('stopService');
      }
    } catch (e) {
      debugPrint('No se pudo detener el foreground service: $e');
    }
  }

  @override
  Future<void> stopTracking() async {
    try {
      if (await _service.isRunning()) {
        _service.invoke('track', {'passengerId': null});
      }
    } catch (e) {
      debugPrint('No se pudo detener el tracking del foreground service: $e');
    }
  }

  @override
  Future<bool> isRunning() => _service.isRunning();
}
