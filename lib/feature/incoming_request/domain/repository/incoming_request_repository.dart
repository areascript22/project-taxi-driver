import 'package:dartz/dartz.dart';

import '../../../../core/error/errors.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/domain/entity/user_location.dart';
import '../entity/incoming_request_entity.dart';

abstract class IncomingRequestRepository {
  Stream<IncomingRequestEntity> get onRequestAdded;
  Stream<IncomingRequestEntity> get onRequestChanged;
  Stream<String> get onRequestRemoved;
  Future<Either<Failure, bool>> acceptRide({
    required String passengerId,
    required UserEntity driverEntity,
    required UserLocation driverLocation,
  });
}