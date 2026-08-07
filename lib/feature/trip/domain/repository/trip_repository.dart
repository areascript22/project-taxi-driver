import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/trip_status_entity.dart';

abstract class TripRepository {
  // Observa el estado del viaje en curso, incluyendo cancelaciones hechas
  // por el pasajero mientras el conductor está en la pantalla del viaje.
  Stream<TripStatusEntity> watchTrip({required String passengerId});

  // Cancela un viaje ya en progreso desde el lado del conductor.
  Future<Either<Failure, Unit>> cancelRide({required String passengerId});

  // Reporta la posición actual del conductor mientras el viaje está activo.
  // La escribe el foreground service cada 5 segundos.
  Future<Either<Failure, Unit>> updateDriverLocation({
    required String passengerId,
    required double latitude,
    required double longitude,
  });
}
