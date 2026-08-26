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
}
