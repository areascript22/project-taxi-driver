import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/errors.dart';
import '../../../domain/entity/user_location.dart';

abstract class GeolocatorService {
  Future<Either<Failure, LocationPermission>> checkAndRequestPermission();
  // Consulta el permiso actual sin disparar el diálogo nativo del SO.
  Future<Either<Failure, LocationPermission>> checkPermission();

  // Lee la posición actual. [timeLimit] acota la espera: sin él, un GPS sin
  // señal puede dejar la llamada colgada para siempre. El motivo del fallo
  // llega en el FailureCode (gpsDisabled, locationPermissionDenied,
  // locationUnavailable...) para poder explicárselo al conductor.
  Future<Either<Failure, UserLocation>> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 10),
  });

  Future<Either<Failure, bool>> openAppSettings();

  // Abre los ajustes de ubicación del dispositivo (donde se enciende el GPS y
  // se sube la precisión).
  Future<Either<Failure, bool>> openLocationSettings();
}
