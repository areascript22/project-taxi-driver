import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/dispatch_change_entity.dart';
import '../../domain/entity/dispatch_config_entity.dart';
import '../../domain/entity/dispatch_ring_entity.dart';
import '../../domain/repository/dispatch_admin_repository.dart';
import '../model/dispatch_change_model.dart';
import '../model/dispatch_config_model.dart';

// La configuración del despacho vive en el servidor
// (/api/admin/dispatch/config); la app solo la muestra y manda el reemplazo
// completo. Lo que cada persona puede hacer lo dice el servidor en la
// respuesta (canEdit, canChangeAdminEditing), no se deduce del rol.
class DispatchAdminRepositoryImpl implements DispatchAdminRepository {
  /// [dio] es inyectable para probar sin red; sin él se usa DioClient.instance.
  DispatchAdminRepositoryImpl({Dio? dio}) : _injectedDio = dio;

  final Dio? _injectedDio;

  // Lazy a propósito: crear el Dio de forma anticipada inicializa dotenv (ver
  // DioClient) y el repositorio se debe poder construir sin eso.
  late final Dio _dio = _injectedDio ?? DioClient.instance;

  static const _path = '/api/admin/dispatch/config';

  @override
  Future<Either<Failure, DispatchConfigEntity>> getConfig() async {
    try {
      final response = await _dio.get(_path);
      return Right(_configFrom(response));
    } catch (e) {
      debugPrint('DispatchAdminDebug | Error en getConfig: $e');
      return Left(_failureOf(e, fallback: FailureCode.dispatchConfigFetchFailed));
    }
  }

  @override
  Future<Either<Failure, DispatchConfigEntity>> saveConfig({
    required List<DispatchRingEntity> rings,
    required int locationMaxAgeSeconds,
    required int expectedVersion,
  }) async {
    try {
      final response = await _dio.put(
        _path,
        data: {
          'rings':
              rings
                  .map((ring) => DispatchRingModel.fromEntity(ring).toJson())
                  .toList(),
          'locationMaxAgeSeconds': locationMaxAgeSeconds,
          'expectedVersion': expectedVersion,
        },
        // Un reintento automático tras un timeout llegaría con la versión ya
        // vieja y devolvería un conflicto falso sobre un guardado que sí se hizo.
        options: Options()..disableRetry = true,
      );
      return Right(_configFrom(response));
    } catch (e) {
      debugPrint('DispatchAdminDebug | Error en saveConfig: $e');
      return Left(_failureOf(e, fallback: FailureCode.dispatchConfigSaveFailed));
    }
  }

  @override
  Future<Either<Failure, DispatchConfigEntity>> setAdminEditing({
    required bool enabled,
  }) async {
    try {
      final response = await _dio.put(
        '$_path/admin-editing',
        data: {'enabled': enabled},
        options: Options()..disableRetry = true,
      );
      return Right(_configFrom(response));
    } catch (e) {
      debugPrint('DispatchAdminDebug | Error en setAdminEditing: $e');
      return Left(_failureOf(e, fallback: FailureCode.dispatchConfigSaveFailed));
    }
  }

  @override
  Future<Either<Failure, DispatchHistoryPageEntity>> getHistory({
    required int limit,
    int? beforeId,
  }) async {
    try {
      final response = await _dio.get(
        '$_path/history',
        queryParameters: {'limit': limit, if (beforeId != null) 'beforeId': beforeId},
      );
      final page = DispatchHistoryPageModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return Right(page.toEntity());
    } catch (e) {
      debugPrint('DispatchAdminDebug | Error en getHistory: $e');
      return Left(
        _failureOf(e, fallback: FailureCode.dispatchHistoryFetchFailed),
      );
    }
  }

  DispatchConfigEntity _configFrom(Response<dynamic> response) {
    return DispatchConfigModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    ).toEntity();
  }

  // 403: sin permiso. 409: otro administrador guardó antes. 400: el servidor
  // rechazó los valores (la app ya los valida, así que es raro). Lo demás es el
  // fallo propio de la operación. El texto del servidor no se muestra: la UI
  // decide el suyo, traducido.
  Failure _failureOf(Object error, {required FailureCode fallback}) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 403:
          return Failure(code: FailureCode.noPermission, detail: '$error');
        case 409:
          return Failure(
            code: FailureCode.dispatchConfigConflict,
            detail: '$error',
          );
        case 400:
          return Failure(
            code: FailureCode.dispatchConfigInvalid,
            detail: '$error',
          );
      }
    }
    return Failure(code: fallback, detail: '$error');
  }
}
