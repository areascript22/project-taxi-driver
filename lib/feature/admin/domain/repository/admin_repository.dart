import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/admin_driver_entity.dart';
import '../entity/driver_page_entity.dart';

abstract class AdminRepository {
  // Una página (paginación por cursor) -- usado por la navegación normal de
  // la lista, para no traer a todos los conductores de una sola vez.
  Future<Either<Failure, DriverPageEntity>> listDriversPage({
    required int pageSize,
    String? cursor,
  });

  // Fetch completo -- lo necesita el buscador, que filtra por nombre/correo/
  // teléfono sobre TODOS los conductores, no solo la página visible.
  Future<Either<Failure, List<AdminDriverEntity>>> searchAllDrivers();

  // Refresco puntual de un solo conductor -- se usa al volver de la
  // pantalla de detalle, para resincronizar ese registro sin recargar la
  // lista paginada entera. Right(null) significa que ya no existe
  // (se eliminó mientras se veía el detalle).
  Future<Either<Failure, AdminDriverEntity?>> getDriver({required String uid});

  Future<Either<Failure, Unit>> deleteDriver({required String uid});

  Future<Either<Failure, Unit>> updateDriverRole({
    required String uid,
    required String role,
  });

  // status: 'approved' | 'rejected'. reason es obligatorio solo para 'rejected'.
  Future<Either<Failure, Unit>> updateApprovalStatus({
    required String uid,
    required String status,
    String? reason,
  });

  // reason es obligatorio cuando blocked == true.
  Future<Either<Failure, Unit>> updateBlockStatus({
    required String uid,
    required bool blocked,
    String? reason,
  });
}
