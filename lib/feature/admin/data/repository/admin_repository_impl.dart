import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/admin_driver_entity.dart';
import '../../domain/repository/admin_repository.dart';
import '../model/admin_driver_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final Dio _dio = DioClient.instance;

  @override
  Future<Either<Failure, List<AdminDriverEntity>>> listDrivers() async {
    try {
      final response = await _dio.get('/api/drivers');
      final data = response.data as List<dynamic>;
      final drivers =
          data
              .map(
                (json) =>
                    AdminDriverModel.fromJson(
                      json as Map<String, dynamic>,
                    ).toEntity(),
              )
              .toList();
      return Right(drivers);
    } on DioException catch (e) {
      debugPrint('AdminDebug | Error en listDrivers: $e');
      if (e.response?.statusCode == 403) {
        return Left(Failure(message: 'No tienes permisos para ver esta lista'));
      }
      return Left(
        Failure(message: 'No se pudo obtener la lista de conductores'),
      );
    } catch (e) {
      debugPrint('AdminDebug | Error inesperado en listDrivers: $e');
      return Left(
        Failure(message: 'No se pudo obtener la lista de conductores'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDriver({required String uid}) async {
    try {
      await _dio.delete('/api/drivers/$uid');
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('AdminDebug | Error en deleteDriver: $e');
      if (e.response?.statusCode == 403) {
        return Left(
          Failure(message: 'No tienes permisos para eliminar a este usuario'),
        );
      }
      if (e.response?.statusCode == 404) {
        return Left(Failure(message: 'El conductor ya no existe'));
      }
      return Left(Failure(message: 'No se pudo eliminar al conductor'));
    } catch (e) {
      debugPrint('AdminDebug | Error inesperado en deleteDriver: $e');
      return Left(Failure(message: 'No se pudo eliminar al conductor'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateDriverRole({
    required String uid,
    required String role,
  }) async {
    try {
      await _dio.put('/api/drivers/$uid/role', data: {'role': role});
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('AdminDebug | Error en updateDriverRole: $e');
      if (e.response?.statusCode == 403) {
        return Left(
          Failure(message: 'No tienes permisos para cambiar este rol'),
        );
      }
      return Left(Failure(message: 'No se pudo actualizar el rol'));
    } catch (e) {
      debugPrint('AdminDebug | Error inesperado en updateDriverRole: $e');
      return Left(Failure(message: 'No se pudo actualizar el rol'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateApprovalStatus({
    required String uid,
    required String status,
    String? reason,
  }) async {
    try {
      await _dio.put(
        '/api/drivers/$uid/approval-status',
        data: {'status': status, 'reason': reason},
      );
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('AdminDebug | Error en updateApprovalStatus: $e');
      if (e.response?.statusCode == 403) {
        return Left(
          Failure(message: 'No tienes permisos para esta acción'),
        );
      }
      if (e.response?.statusCode == 404) {
        return Left(Failure(message: 'El conductor ya no existe'));
      }
      if (e.response?.statusCode == 400) {
        return Left(
          Failure(message: 'Falta el motivo para rechazar al conductor'),
        );
      }
      return Left(
        Failure(message: 'No se pudo actualizar el estado del conductor'),
      );
    } catch (e) {
      debugPrint('AdminDebug | Error inesperado en updateApprovalStatus: $e');
      return Left(
        Failure(message: 'No se pudo actualizar el estado del conductor'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> updateBlockStatus({
    required String uid,
    required bool blocked,
    String? reason,
  }) async {
    try {
      await _dio.put(
        '/api/drivers/$uid/block-status',
        data: {'blocked': blocked, 'reason': reason},
      );
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('AdminDebug | Error en updateBlockStatus: $e');
      if (e.response?.statusCode == 403) {
        return Left(
          Failure(message: 'No tienes permisos para esta acción'),
        );
      }
      if (e.response?.statusCode == 404) {
        return Left(Failure(message: 'El conductor ya no existe'));
      }
      if (e.response?.statusCode == 409) {
        return Left(
          Failure(
            message: 'No se puede bloquear a un conductor que no está aprobado',
          ),
        );
      }
      if (e.response?.statusCode == 400) {
        return Left(Failure(message: 'Falta el motivo del bloqueo'));
      }
      return Left(
        Failure(message: 'No se pudo actualizar el bloqueo del conductor'),
      );
    } catch (e) {
      debugPrint('AdminDebug | Error inesperado en updateBlockStatus: $e');
      return Left(
        Failure(message: 'No se pudo actualizar el bloqueo del conductor'),
      );
    }
  }
}
