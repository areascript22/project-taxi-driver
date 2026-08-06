import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/errors.dart';
import '../../../domain/entity/user_location.dart';

abstract class GeolocatorService {
  Future<Either<Failure, LocationPermission>> checkAndRequestPermission();
  // Consulta el permiso actual sin disparar el diálogo nativo del SO.
  Future<Either<Failure, LocationPermission>> checkPermission();
  Future<Either<Failure, UserLocation>> getCurrentPosition();
  Future<Either<Failure, bool>> openAppSettings();
}
