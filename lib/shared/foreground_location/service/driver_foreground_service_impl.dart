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
      debugPrint(
        'ForegroundLocationDebug | start() llamado con passengerId=$passengerId',
      );

      // Android 13+ exige el permiso runtime para poder mostrar la
      // notificación persistente del servicio. Si el usuario lo niega, el
      // servicio igual arranca y sigue trackeando -- simplemente no se ve.
      final notificationStatus = await Permission.notification.request();
      debugPrint(
        'ForegroundLocationDebug | Permission.notification -> $notificationStatus',
      );

      final wasRunning = await _service.isRunning();
      debugPrint('ForegroundLocationDebug | isRunning antes de start -> $wasRunning');

      if (!wasRunning) {
        await _service.startService();
        debugPrint('ForegroundLocationDebug | startService() completado');
      }

      _service.invoke('track', {'passengerId': passengerId});
      debugPrint(
        'ForegroundLocationDebug | invoke(track, passengerId=$passengerId) enviado',
      );
    } catch (e) {
      debugPrint('ForegroundLocationDebug | No se pudo iniciar el foreground service: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (await _service.isRunning()) {
        _service.invoke('stopService');
        debugPrint('ForegroundLocationDebug | invoke(stopService) enviado');
      } else {
        debugPrint('ForegroundLocationDebug | stop() llamado pero el servicio ya no corría');
      }
    } catch (e) {
      debugPrint('ForegroundLocationDebug | No se pudo detener el foreground service: $e');
    }
  }

  @override
  Future<void> stopTracking() async {
    try {
      if (await _service.isRunning()) {
        _service.invoke('track', {'passengerId': null});
        debugPrint('ForegroundLocationDebug | invoke(track, passengerId=null) enviado');
      } else {
        debugPrint(
          'ForegroundLocationDebug | stopTracking() llamado pero el servicio ya no corría',
        );
      }
    } catch (e) {
      debugPrint(
        'ForegroundLocationDebug | No se pudo detener el tracking del foreground service: $e',
      );
    }
  }

  @override
  Future<bool> isRunning() => _service.isRunning();
}
