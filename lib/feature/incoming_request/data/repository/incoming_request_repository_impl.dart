import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../../core/error/errors.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/domain/entity/user_location.dart';
import '../../domain/entity/incoming_request_entity.dart';
import '../../domain/repository/incoming_request_repository.dart';

class IncomingRequestRepositoryImpl implements IncomingRequestRepository {
  final Query _pendingRequestsQuery = FirebaseDatabase.instance
      .ref('taxi_requests')
      .orderByChild('status')
      .equalTo('pending');

  @override
  Stream<IncomingRequestEntity> get onRequestAdded {
    return _pendingRequestsQuery.onChildAdded.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return IncomingRequestEntity.fromMap(data);
    });
  }

  @override
  Stream<IncomingRequestEntity> get onRequestChanged {
    return _pendingRequestsQuery.onChildChanged.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return IncomingRequestEntity.fromMap(data);
    });
  }

  @override
  Stream<String> get onRequestRemoved {
    return _pendingRequestsQuery.onChildRemoved.map((event) {
      // En Firebase, onChildRemoved devuelve el snapshot con la data original
      // antes de que fuera eliminada o dejara de coincidir con el query.
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      // Extraemos el rideId exacto directamente del objeto
      if (data != null && data.containsKey('rideId')) {
        return data['rideId'].toString();
      }

      // Fallback por seguridad
      return event.snapshot.key ?? '';
    });
  }

  @override
  Future<Either<Failure, bool>> acceptRide({
    required String passengerId,
    required UserEntity driverEntity,
    required UserLocation driverLocation,
  }) async {
    try {
      final DatabaseReference ref = FirebaseDatabase.instance.ref(
        'taxi_requests/$passengerId',
      );

      final TransactionResult result = await ref.runTransaction((mutableData) {
        if (mutableData == null) {
          return Transaction.abort();
        }

        final data = Map<dynamic, dynamic>.from(mutableData as Map);

        if (data['status'] != 'pending') {
          return Transaction.abort();
        }

        data['status'] = 'driverAssigned';
        data['driver'] = {
          'data': {
            'id': driverEntity.id, //[cite: 2]
            'email': driverEntity.email, //[cite: 2]
            'displayName': driverEntity.displayName, //[cite: 2]
            'photoUrl': driverEntity.photoUrl, //[cite: 2]
          },
          'location': {
            'latitude': driverLocation.latitude, //[cite: 3]
            'longitude': driverLocation.longitude, //[cite: 3]
          },
        };

        return Transaction.success(data);
      });

      if (!result.committed) {
        return Left(
          Failure(
            message:
                'La carrera ya fue tomada por otro conductor o ya no está disponible.',
          ),
        ); //[cite: 4]
      }

      return const Right(true);
    } catch (e) {
      return Left(Failure(message: e.toString())); //[cite: 4]
    }
  }
}
