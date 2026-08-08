import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../../../incoming_request/domain/entity/incoming_request_entity.dart';
import '../entity/trip_status_entity.dart';

abstract class TripRepository {
  // Observa el estado del viaje en curso, incluyendo cancelaciones hechas
  // por el pasajero mientras el conductor está en la pantalla del viaje.
  Stream<TripStatusEntity> watchTrip({required String passengerId});

  // Busca si el conductor tiene un viaje activo (asignado, llegó, o en
  // camino -- no cancelado ni finalizado) en cualquier taxi_request. Se usa
  // al iniciar la app para decidir si hay que resumir TripScreen en vez de
  // ir a IncomingRequestScreen. Null == no hay viaje en curso.
  Future<Either<Failure, IncomingRequestEntity?>> findActiveTripForDriver({
    required String driverId,
  });

  // Cancela un viaje ya en progreso desde el lado del conductor.
  Future<Either<Failure, Unit>> cancelRide({required String passengerId});

  // El conductor llegó al punto de recogida.
  Future<Either<Failure, Unit>> markDriverArrived({required String passengerId});

  // El viaje llegó a su destino y finalizó.
  Future<Either<Failure, Unit>> completeTrip({required String passengerId});

  // Reporta la posición actual del conductor mientras el viaje está activo.
  // La escribe el foreground service cada 5 segundos.
  Future<Either<Failure, Unit>> updateDriverLocation({
    required String passengerId,
    required double latitude,
    required double longitude,
  });
}
