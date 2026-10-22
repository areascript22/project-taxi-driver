import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/errors.dart';
import '../../domain/location_failure_mapper.dart';
import '../../../domain/entity/user_location.dart';
import 'geolocator_service.dart';

class GeolocatorServiceServiceImpl implements GeolocatorService {
  @override
  Future<Either<Failure, LocationPermission>>
  checkAndRequestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint(
        'GeolocatorDebug | checkAndRequestPermission -> permiso actual: $permission',
      );

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint(
          'GeolocatorDebug | checkAndRequestPermission -> permiso tras requestPermission(): $permission',
        );
      }

      return Right(permission);
    } catch (e) {
      debugPrint('GeolocatorDebug | Error en checkAndRequestPermission: $e');
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LocationPermission>> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      debugPrint('GeolocatorDebug | checkPermission -> $permission');
      return Right(permission);
    } catch (e) {
      debugPrint('GeolocatorDebug | Error en checkPermission: $e');
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLocation>> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint(
        'GeolocatorDebug | isLocationServiceEnabled -> $isServiceEnabled',
      );
      if (!isServiceEnabled) {
        return Left(Failure(code: FailureCode.gpsDisabled));
      }

      final permission = await Geolocator.checkPermission();
      debugPrint(
        'GeolocatorDebug | getCurrentPosition -> permiso actual: $permission',
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: timeLimit,
        ),
      );
      debugPrint(
        'GeolocatorDebug | getCurrentPosition -> posición obtenida: '
        '(${position.latitude}, ${position.longitude})',
      );

      return Right(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (e) {
      debugPrint('GeolocatorDebug | Error en getCurrentPosition: $e');
      // El motivo real (GPS/ajustes apagados, permiso, sin señal a tiempo) llega
      // como código para poder explicárselo al conductor, no como `unexpected`.
      return Left(
        Failure(code: locationFailureCodeOf(e), detail: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> openLocationSettings() async {
    try {
      final response = await Geolocator.openLocationSettings();
      return Right(response);
    } catch (e) {
      debugPrint('GeolocatorDebug | Error en openLocationSettings: $e');
      return Left(
        Failure(code: FailureCode.appSettingsFailed, detail: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> openAppSettings() async {
    try {
      final response = await Geolocator.openAppSettings();
      return Right(response);
    } catch (e) {
      debugPrint('GeolocatorDebug | Error en openAppSettings: $e');
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }
}
