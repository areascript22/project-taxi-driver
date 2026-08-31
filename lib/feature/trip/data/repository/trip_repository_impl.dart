import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../incoming_request/domain/entity/incoming_request_entity.dart';
import '../../domain/entity/trip_status_entity.dart';
import '../../domain/repository/trip_repository.dart';

// Statuses que cuentan como "viaje en curso" para findActiveTripForDriver --
// 'pending' no aplica (todavía no tiene driver asignado) y 'cancelled' /
// 'tripCompleted' ya terminaron.
const _activeTripStatuses = {'driverAssigned', 'driverArrived', 'tripStarted'};

class TripRepositoryImpl implements TripRepository {
  final Dio _dio = DioClient.instance;

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
  Future<Either<Failure, IncomingRequestEntity?>> findActiveTripForDriver({
    required String driverId,
  }) async {
    try {
      // Sin orderByChild/equalTo a propósito: esas queries requieren un
      // ".indexOn" declarado en las reglas de Firebase para /taxi_requests.
      // Los listeners en streaming (onChildAdded/onValue, como en
      // IncomingRequestRepositoryImpl) solo emiten un warning si falta ese
      // índice y siguen funcionando -- pero un .get() puntual sin índice
      // lanza una excepción dura del servidor ("Index not defined..."), que
      // acá terminaba en el catch y se interpretaba como "no hay viaje".
      // Traer el nodo completo una sola vez y filtrar en Dart evita
      // depender de que ese índice esté configurado.
      final snapshot =
          await FirebaseDatabase.instance.ref('taxi_requests').get();
      final rawValue = snapshot.value;
      if (rawValue == null) return const Right(null);

      final allRequests = Map<dynamic, dynamic>.from(rawValue as Map);

      for (final entry in allRequests.values) {
        final data = Map<dynamic, dynamic>.from(entry as Map);
        if (!_activeTripStatuses.contains(data['status'])) continue;

        final driverNode = data['driver'];
        final driverData = driverNode is Map ? driverNode['data'] : null;
        final assignedDriverId = driverData is Map ? driverData['id'] : null;

        if (assignedDriverId == driverId) {
          return Right(IncomingRequestEntity.fromMap(data));
        }
      }

      return const Right(null);
    } catch (e) {
      debugPrint("Error al verificar si hay un viaje activo: $e");
      return Left(
        Failure(message: 'No se pudo verificar si tienes un viaje en curso.'),
      );
    }
  }

  // Ya no escribe directo a Realtime Database: pasa por el backend
  // (RideService.cancelRide) para que verifique con el token de Firebase
  // que quien cancela es el conductor realmente asignado, y para que el
  // servidor pueda avisarle al pasajero por push (el cliente no tiene
  // acceso al Admin SDK de FCM).
  @override
  Future<Either<Failure, Unit>> cancelRide({required String passengerId}) async {
    try {
      await _dio.post('/api/rides/$passengerId/cancel');
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('TripDebug | Error en cancelRide: $e');
      if (e.response?.statusCode == 403) {
        return Left(
          Failure(message: 'No tienes permiso para cancelar esta carrera.'),
        );
      }
      if (e.response?.statusCode == 404 || e.response?.statusCode == 409) {
        return Left(
          Failure(message: 'La carrera ya no está disponible para cancelar.'),
        );
      }
      return Left(
        Failure(message: 'No se pudo cancelar la carrera. Intenta de nuevo.'),
      );
    } catch (e) {
      debugPrint('TripDebug | Error inesperado en cancelRide: $e');
      return Left(
        Failure(message: 'No se pudo cancelar la carrera. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> markDriverArrived({
    required String passengerId,
  }) async {
    try {
      await FirebaseDatabase.instance.ref('taxi_requests/$passengerId').update({
        'status': 'driverArrived',
        'updatedAt': ServerValue.timestamp,
      });
      return const Right(unit);
    } catch (e) {
      return Left(
        Failure(message: 'No se pudo notificar tu llegada. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> completeTrip({
    required String passengerId,
  }) async {
    try {
      await FirebaseDatabase.instance.ref('taxi_requests/$passengerId').update({
        'status': 'tripCompleted',
        'updatedAt': ServerValue.timestamp,
      });
      return const Right(unit);
    } catch (e) {
      return Left(
        Failure(message: 'No se pudo finalizar el viaje. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> updateDriverLocation({
    required String passengerId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await FirebaseDatabase.instance
          .ref('taxi_requests/$passengerId/driver/location')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'updatedAt': ServerValue.timestamp,
          });
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: 'No se pudo actualizar la ubicación del conductor.'));
    }
  }
}
