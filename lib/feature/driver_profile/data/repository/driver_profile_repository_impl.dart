import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/driver_entity.dart';
import '../../domain/entity/vehicle_entity.dart';
import '../../domain/repository/driver_profile_repository.dart';
import '../model/driver_model.dart';
import '../model/vehicle_model.dart';

/// Sube [file] a [path] en Storage y devuelve su URL de descarga.
typedef ProfilePhotoUploader = Future<String> Function({
  required String path,
  required File file,
});

// Los perfiles viven en Postgres y se leen/escriben por el servidor:
// GET /api/me devuelve la persona con su perfil de conductor y su vehiculo;
// PUT /api/me/driver-profile los crea o actualiza. Lo unico que la app sigue
// haciendo directo es subir la foto a Storage (reglas por uid) y mandarle la
// URL al servidor.
class DriverProfileRepositoryImpl implements DriverProfileRepository {
  /// [dio] y [photoUploader] son inyectables para probar sin red ni Firebase;
  /// sin ellos se usan DioClient.instance y Firebase Storage.
  DriverProfileRepositoryImpl({Dio? dio, ProfilePhotoUploader? photoUploader})
    : _injectedDio = dio,
      _photoUploader = photoUploader ?? _uploadToStorage;

  final Dio? _injectedDio;
  final ProfilePhotoUploader _photoUploader;

  // Lazy a proposito: crear el Dio de forma anticipada inicializa dotenv (ver
  // DioClient) y el repositorio se debe poder construir sin eso.
  late final Dio _dio = _injectedDio ?? DioClient.instance;

  static Future<String> _uploadToStorage({
    required String path,
    required File file,
  }) async {
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  @override
  Future<Either<Failure, DriverEntity?>> getDriver({
    required String driverId,
  }) async {
    try {
      final me = await _fetchMe();
      return Right(DriverModel.fromMe(me)?.toEntity());
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en getDriver: $e');
      return Left(
        Failure(code: FailureCode.driverProfileCheckFailed),
      );
    }
  }

  // El vehiculo viaja dentro de /api/me; `vehicleId` se conserva en la firma
  // por compatibilidad: el servidor siempre devuelve el de la sesion.
  @override
  Future<Either<Failure, VehicleEntity?>> getVehicle({
    required String vehicleId,
  }) async {
    try {
      final me = await _fetchMe();
      return Right(VehicleModel.fromMe(me)?.toEntity());
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en getVehicle: $e');
      return Left(
        Failure(code: FailureCode.vehicleFetchFailed),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> registerDriver({
    required DriverEntity driver,
    required VehicleEntity vehicle,
    File? profileImage,
  }) async {
    try {
      String? photoUrl = driver.photoUrl;

      if (profileImage != null) {
        photoUrl = await _photoUploader(
          path: 'driver_profile_photos/${driver.id}.jpg',
          file: profileImage,
        );
      }

      await _dio.put(
        '/api/me/driver-profile',
        data: {
          'firstName': driver.firstName,
          'lastName': driver.lastName,
          'phoneNumber': driver.phoneNumber,
          if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
          'vehicle': {
            'plate': vehicle.plate,
            'brand': vehicle.brand,
            'model': vehicle.model,
            'year': vehicle.year,
            'color': vehicle.color,
            'registrationNumber': vehicle.registrationNumber,
          },
        },
        options: Options()..disableRetry = true,
      );

      return const Right(unit);
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en registerDriver: $e');
      return Left(
        Failure(code: FailureCode.profileSaveFailed),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchMe() async {
    final response = await _dio.get('/api/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  // El token de notificaciones y el idioma ya no se escriben directo en
  // Firestore: van al servidor (PUT /api/me/device), que sabe de que persona
  // y de que app son por el token de sesion. `driverId` se conserva en la
  // firma por compatibilidad con los llamadores, pero el servidor NO lo usa:
  // la identidad sale siempre del token.
  @override
  Future<Either<Failure, Unit>> updateFcmToken({
    required String driverId,
    required String token,
    required String language,
  }) async {
    try {
      await _dio.put(
        '/api/me/device',
        data: {'app': 'driver', 'fcmToken': token, 'language': language},
      );
      return const Right(unit);
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en updateFcmToken: $e');
      return Left(
        Failure(code: FailureCode.fcmTokenSaveFailed),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> updateLanguage({
    required String driverId,
    required String language,
  }) async {
    try {
      await _dio.put(
        '/api/me/device',
        data: {'app': 'driver', 'language': language},
      );
      return const Right(unit);
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en updateLanguage: $e');
      return Left(
        Failure(code: FailureCode.pushLanguageSaveFailed),
      );
    }
  }
}
