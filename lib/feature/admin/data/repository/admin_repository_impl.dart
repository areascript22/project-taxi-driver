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
}
