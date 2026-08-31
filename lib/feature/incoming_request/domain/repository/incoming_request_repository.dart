import 'package:dartz/dartz.dart';

import '../../../../core/error/errors.dart';
import '../../../../shared/domain/entity/user_location.dart';
import '../entity/incoming_request_entity.dart';

abstract class IncomingRequestRepository {
  Stream<IncomingRequestEntity> get onRequestAdded;
  Stream<IncomingRequestEntity> get onRequestChanged;
  Stream<String> get onRequestRemoved;

  // La identidad del conductor ya no se envía desde el cliente: el backend
  // la deriva del token de Firebase verificado. Solo se envía la ubicación
  // actual, que el servidor no tiene forma de conocer por su cuenta.
  Future<Either<Failure, bool>> acceptRide({
    required String passengerId,
    required UserLocation driverLocation,
  });
}