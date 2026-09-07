import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../incoming_request/domain/entity/incoming_request_entity.dart';
import '../../domain/entity/trip_status_entity.dart';
import '../../domain/repository/trip_repository.dart';

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

  // Ya no escanea /taxi_requests completo client-side (eso descargaba al
  // dispositivo del conductor la data de TODAS las solicitudes activas,
  // incluyendo pickup/nombre de pasajeros ajenos, solo para filtrar la
  // suya en Dart -- ver RideService.findActiveRideForDriver). Pasa por el
  // backend, que identifica al conductor por el token verificado y hace el
  // filtrado server-side, devolviendo solo el viaje que le pertenece.
  @override
  Future<Either<Failure, IncomingRequestEntity?>> findActiveTripForDriver() async {
    try {
      final response = await _dio.get('/api/rides/driver/active');
      if (response.statusCode == 204 || response.data == null) {
        return const Right(null);
      }

      final data = Map<dynamic, dynamic>.from(response.data as Map);
      return Right(IncomingRequestEntity.fromMap(data));
    } on DioException catch (e) {
      debugPrint('TripDebug | Error en findActiveTripForDriver: $e');
      return Left(
        Failure(message: 'No se pudo verificar si tienes un viaje en curso.'),
      );
    } catch (e) {
      debugPrint('TripDebug | Error inesperado en findActiveTripForDriver: $e');
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

  // Ya no escribe directo a Realtime Database: pasa por el backend
  // (RideService.completeTrip) para que verifique que quien finaliza es el
  // conductor realmente asignado, y para que el servidor pueda borrar la
  // solicitud de Firebase unos segundos después (limpieza que no depende de
  // que la app siga abierta).
  @override
  Future<Either<Failure, Unit>> completeTrip({
    required String passengerId,
  }) async {
    try {
      await _dio.post('/api/rides/$passengerId/complete');
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('TripDebug | Error en completeTrip: $e');
      if (e.response?.statusCode == 403) {
        return Left(
          Failure(message: 'No tienes permiso para finalizar este viaje.'),
        );
      }
      if (e.response?.statusCode == 404 || e.response?.statusCode == 409) {
        return Left(
          Failure(message: 'El viaje ya no está disponible para finalizar.'),
        );
      }
      return Left(
        Failure(message: 'No se pudo finalizar el viaje. Intenta de nuevo.'),
      );
    } catch (e) {
      debugPrint('TripDebug | Error inesperado en completeTrip: $e');
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
