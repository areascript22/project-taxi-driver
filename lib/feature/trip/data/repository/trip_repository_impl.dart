import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../../core/error/errors.dart';
import '../../domain/entity/trip_status_entity.dart';
import '../../domain/repository/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  @override
  Stream<TripStatusEntity> watchTrip({required String passengerId}) {
    return FirebaseDatabase.instance
        .ref('taxi_requests/$passengerId')
        .onValue
        .map((event) {
          final raw = event.snapshot.value;
          final map =
              raw == null
                  ? <dynamic, dynamic>{}
                  : Map<dynamic, dynamic>.from(raw as Map);

          return TripStatusEntity.fromMap(map);
        });
  }

  @override
  Future<Either<Failure, Unit>> cancelRide({required String passengerId}) async {
    try {
      await FirebaseDatabase.instance.ref('taxi_requests/$passengerId').update({
        'status': 'cancelled',
        'cancelledBy': 'driver',
        'updatedAt': ServerValue.timestamp,
      });
      return const Right(unit);
    } catch (e) {
      return Left(
        Failure(message: 'No se pudo cancelar la carrera. Intenta de nuevo.'),
      );
    }
  }
}
