import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/admin_driver_entity.dart';
import '../../domain/entity/driver_page_entity.dart';
import '../../domain/repository/admin_repository.dart';
import '../model/admin_driver_model.dart';
import '../model/driver_page_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final Dio _dio = DioClient.instance;

  @override
  Future<Either<Failure, DriverPageEntity>> listDriversPage({
    required int pageSize,
    String? cursor,
  }) async {
    try {
      final response = await _dio.get(
        '/api/drivers',
        queryParameters: {
          'pageSize': pageSize,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final page = DriverPageModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return Right(page.toEntity());
    } on DioException catch (e) {
      debugPrint('AdminDebug | Error en listDriversPage: $e');
      if (e.response?.statusCode == 403) {
        return Left(Failure(message: 'No tienes permisos para ver esta lista'));
      }
      return Left(
        Failure(message: 'No se pudo obtener la lista de conductores'),
      );
    } catch (e) {
      debugPrint('AdminDebug | Error inesperado en listDriversPage: $e');
      return Left(
        Failure(message: 'No se pudo obtener la lista de conductores'),
      );
    }
  }

  @override
  Future<Either<Failure, List<AdminDriverEntity>>> searchAllDrivers() async {
    try {
      final response = await _dio.get('/api/drivers');
      final page = DriverPageModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return Right(page.drivers.map((model) => model.toEntity()).toList());
    } on DioException catch (e) {
      debugPrint('AdminDebug | Error en searchAllDrivers: $e');
      if (e.response?.statusCode == 403) {
        return Left(Failure(message: 'No tienes permisos para ver esta lista'));
      }
      return Left(
        Failure(message: 'No se pudo obtener la lista de conductores'),
      );
    } catch (e) {
      debugPrint('AdminDebug | Error inesperado en searchAllDrivers: $e');
      return Left(
        Failure(message: 'No se pudo obtener la lista de conductores'),
      );
    }
  }

  @override
  Future<Either<Failure, AdminDriverEntity?>> getDriver({
    required String uid,
  }) async {
    try {
      final response = await _dio.get('/api/drivers/$uid');
      final driver = AdminDriverModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
      return Right(driver);
    } on DioException catch (e) {
      debugPrint('AdminDebug | Error en getDriver: $e');
      if (e.response?.statusCode == 404) {
        return const Right(null);
      }
      if (e.response?.statusCode == 403) {
        return Left(Failure(message: 'No tienes permisos para ver este conductor'));
      }
      return Left(Failure(message: 'No se pudo actualizar la información del conductor'));
    } catch (e) {
      debugPrint('AdminDebug | Error inesperado en getDriver: $e');
      return Left(Failure(message: 'No se pudo actualizar la información del conductor'));
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
