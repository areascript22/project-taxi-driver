import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/errors.dart';
import '../../../domain/entity/user_location.dart';
import 'geolocator_service.dart';

class GeolocatorServiceServiceImpl implements GeolocatorService {
  @override
  Future<Either<Failure, LocationPermission>> checkAndRequestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('GeolocatorDebug | checkAndRequestPermission -> permiso actual: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint(
          'GeolocatorDebug | checkAndRequestPermission -> permiso tras requestPermission(): $permission',
        );
      }

      return Right(permission);
    } catch (e) {
      debugPrint('GeolocatorDebug | Error en checkAndRequestPermission: $e');
      return Left(Failure(message: e.toString()));
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
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLocation>> getCurrentPosition() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('GeolocatorDebug | isLocationServiceEnabled -> $isServiceEnabled');
      if (!isServiceEnabled) {
        return Left(Failure(message: 'El servicio de GPS del dispositivo está desactivado.'));
      }

      final permission = await Geolocator.checkPermission();
      debugPrint('GeolocatorDebug | getCurrentPosition -> permiso actual: $permission');

      final position = await Geolocator.getCurrentPosition();
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
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> openAppSettings() async {
    try {
      final response = await Geolocator.openAppSettings();
      return Right(response);
    } catch (e) {
      debugPrint('GeolocatorDebug | Error en openAppSettings: $e');
      return Left(Failure(message: e.toString()));
    }
  }
}
