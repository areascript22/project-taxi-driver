import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/core/network/dio_client.dart';
import 'package:driver_app/feature/app_update/data/model/update_requirement_model.dart';
import 'package:driver_app/feature/app_update/domain/entity/update_requirement_entity.dart';
import 'package:driver_app/feature/app_update/domain/repository/app_update_repository.dart';
import 'package:flutter/material.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  /// [appId] es el identificador de esta app en el servidor ("driver").
  /// [readVersion] devuelve la versión instalada tal cual la reporta el
  /// sistema (ej. "1.0.7-dev+19"): el servidor ignora el sufijo y el build.
  ///
  /// [dio] es inyectable (default DioClient.instance) para poder mockearlo.
  AppUpdateRepositoryImpl({
    required this.appId,
    required this.readVersion,
    Dio? dio,
  }) : _dio = dio ?? DioClient.instance;

  final String appId;
  final Future<String?> Function() readVersion;
  final Dio _dio;

  @override
  Future<Either<Failure, UpdateRequirementEntity>> checkUpdate() async {
    try {
      final version = await readVersion();
      if (version == null || version.trim().isEmpty) {
        debugPrint('AppUpdateDebug | No se pudo leer la versión instalada');
        return Left(Failure(code: FailureCode.appUpdateCheckFailed));
      }

      final response = await _dio.get(
        '/api/public/app-version',
        queryParameters: {'app': appId, 'version': version},
      );
      final model = UpdateRequirementModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return Right(model.toEntity());
    } catch (e) {
      debugPrint('AppUpdateDebug | Error en checkUpdate: $e');
      return Left(Failure(code: FailureCode.appUpdateCheckFailed));
    }
  }
}
