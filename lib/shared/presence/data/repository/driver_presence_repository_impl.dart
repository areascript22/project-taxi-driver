import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repository/driver_presence_repository.dart';

class DriverPresenceRepositoryImpl implements DriverPresenceRepository {
  /// [dio] es inyectable para poder mockearlo en tests; sin el se usa
  /// DioClient.instance.
  DriverPresenceRepositoryImpl({Dio? dio}) : _injectedDio = dio;

  final Dio? _injectedDio;

  // Lazy a proposito: crear el Dio de forma anticipada inicializa dotenv, y en
  // el isolate del foreground service (que usa este repositorio) eso tumbaba el
  // arranque (ver DioClient).
  late final Dio _dio = _injectedDio ?? DioClient.instance;

  @override
  Future<Either<Failure, Unit>> setOnline({required bool online}) async {
    try {
      await _dio.put(
        '/api/me/driver/availability',
        data: {'online': online},
      );
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('PresenceDebug | Error en setOnline($online): $e');
      final status = e.response?.statusCode;
      if (status == 403) {
        return Left(Failure(code: FailureCode.onlineNotAllowed));
      }
      if (status == 404) {
        return Left(Failure(code: FailureCode.driverProfileNotReady));
      }
      return Left(Failure(code: FailureCode.onlineFailed));
    } catch (e) {
      debugPrint('PresenceDebug | Error inesperado en setOnline($online): $e');
      return Left(Failure(code: FailureCode.onlineFailed));
    }
  }

  @override
  Future<Either<Failure, Unit>> reportLocation({
    required double latitude,
    required double longitude,
    String? passengerId,
  }) async {
    try {
      await _dio.put(
        '/api/me/driver/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (passengerId != null) 'passengerId': passengerId,
        },
        // Sin reintentos: una posicion vieja es peor que ninguna. Si falla, el
        // siguiente reporte (en unos segundos) trae una mas reciente.
        options: Options()..disableRetry = true,
      );
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('PresenceDebug | Error en reportLocation: $e');
      return Left(
        Failure(
          code: FailureCode.locationUpdateFailed,
          detail: 'HTTP ${e.response?.statusCode ?? e.type.name}',
        ),
      );
    } catch (e) {
      debugPrint('PresenceDebug | Error inesperado en reportLocation: $e');
      return Left(
        Failure(code: FailureCode.locationUpdateFailed, detail: '$e'),
      );
    }
  }
}
