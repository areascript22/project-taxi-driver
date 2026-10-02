import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/admin_driver_entity.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<AdminDriverEntity>>> listDrivers();

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
