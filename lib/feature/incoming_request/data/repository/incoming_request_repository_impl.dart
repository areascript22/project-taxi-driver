import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/entity/user_location.dart';
import '../../domain/entity/incoming_request_entity.dart';
import '../../domain/repository/incoming_request_repository.dart';

class IncomingRequestRepositoryImpl implements IncomingRequestRepository {
  final Dio _dio = DioClient.instance;

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

  // La transacción de asignación (evitar que dos conductores se queden con
  // la misma carrera) ya no vive acá: corre en el backend (RideService),
  // que además deriva la identidad del conductor del token de Firebase
  // verificado en vez de confiar en lo que mande el cliente.
  @override
  Future<Either<Failure, bool>> acceptRide({
    required String passengerId,
    required UserLocation driverLocation,
  }) async {
    try {
      debugPrint('IncomingRequestDebug | starting');
      await _dio.post(
        '/api/rides/$passengerId/accept',
        data: {
          'latitude': driverLocation.latitude,
          'longitude': driverLocation.longitude,
        },
      );
      return const Right(true);
    } on DioException catch (e) {
      debugPrint('IncomingRequestDebug | Error en acceptRide: $e');
      if (e.response?.statusCode == 409) {
        return Left(
          Failure(
            message:
                'La carrera ya fue tomada por otro conductor o ya no está disponible.',
          ),
        );
      }
      if (e.response?.statusCode == 404) {
        return Left(
          Failure(message: 'La solicitud ya no está disponible.'),
        );
      }
      return Left(Failure(message: 'No se pudo aceptar la carrera.'));
    } catch (e) {
      debugPrint('IncomingRequestDebug | Error inesperado en acceptRide: $e');
      return Left(Failure(message: 'No se pudo aceptar la carrera.'));
    }
  }
}
