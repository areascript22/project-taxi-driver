import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/entity/user_location.dart';
import '../../domain/entity/incoming_request_entity.dart';
import '../../domain/repository/incoming_request_repository.dart';

/// Las carreras que el conductor puede aceptar salen de SU bandeja de ofertas,
/// `driver_offers/{uid}`, que escribe el servidor.
///
/// Antes escuchaba todo `taxi_requests` y veia los pedidos de cualquier
/// pasajero, estuvieran a 5 m o a 20 km. Ahora el despacho por cercania le
/// deja en su bandeja solo los que le tocan, y las reglas de la base le
/// permiten leer unicamente su propia rama.
class IncomingRequestRepositoryImpl implements IncomingRequestRepository {
  /// [offersQuery] y [dio] son inyectables para probar sin Firebase real. Por
  /// defecto: la bandeja del usuario autenticado y DioClient.instance.
  IncomingRequestRepositoryImpl({Query? offersQuery, Dio? dio})
    : _injectedOffers = offersQuery,
      _injectedDio = dio;

  final Query? _injectedOffers;
  final Dio? _injectedDio;

  late final Dio _dio = _injectedDio ?? DioClient.instance;

  static const _acceptTimeout = Duration(seconds: 15);

  // null si no hay sesion: sin usuario no hay bandeja que escuchar.
  Query? get _offers {
    if (_injectedOffers != null) return _injectedOffers;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseDatabase.instance.ref('driver_offers/$uid');
  }

  @override
  Stream<IncomingRequestEntity> get onRequestAdded {
    final offers = _offers;
    if (offers == null) return const Stream.empty();
    return offers.onChildAdded
        .map((event) => _asMap(event.snapshot.value))
        .where((data) => data != null && !IncomingRequestEntity.isOfferExpired(data))
        .map((data) => IncomingRequestEntity.fromOffer(data!));
  }

  @override
  Stream<IncomingRequestEntity> get onRequestChanged {
    final offers = _offers;
    if (offers == null) return const Stream.empty();
    return offers.onChildChanged
        .map((event) => _asMap(event.snapshot.value))
        .where((data) => data != null && !IncomingRequestEntity.isOfferExpired(data))
        .map((data) => IncomingRequestEntity.fromOffer(data!));
  }

  @override
  Stream<String> get onRequestRemoved {
    final offers = _offers;
    if (offers == null) return const Stream.empty();
    return offers.onChildRemoved.map((event) {
      // onChildRemoved entrega el snapshot con los datos originales.
      final data = _asMap(event.snapshot.value);
      if (data != null && data.containsKey('rideId')) {
        return data['rideId'].toString();
      }
      return event.snapshot.key ?? '';
    });
  }

  static Map<dynamic, dynamic>? _asMap(Object? value) {
    return value is Map ? Map<dynamic, dynamic>.from(value) : null;
  }

  // La transaccion de asignacion (evitar que dos conductores se queden con
  // la misma carrera) corre en el backend, que ademas deriva la identidad del
  // conductor del token verificado y comprueba que la carrera le fue ofrecida.
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
        // El servidor autoriza al conductor, asigna, notifica y abre el chat
        // antes de responder: con el receiveTimeout global (5s) a veces
        // responde justo despues de que Dio abandono la espera. El
        // RetryInterceptor reenviaba y el reintento recibia 409 ("otro
        // conductor la tomo") sobre una carrera que si era de este conductor.
        // El servidor ya trata ese reintento como exito; este timeout evita
        // ademas que el conductor espere un error que no es.
        options: Options(receiveTimeout: _acceptTimeout),
      );
      return const Right(true);
    } on DioException catch (e) {
      debugPrint('IncomingRequestDebug | Error en acceptRide: $e');
      if (e.response?.statusCode == 409) {
        return Left(
          Failure(code: FailureCode.rideTaken),
        );
      }
      // 404: la carrera ya no existe. (403 -- no aprobado, bloqueado o no
      // ofrecida -- cae en el mensaje generico de abajo.)
      if (e.response?.statusCode == 404) {
        return Left(
          Failure(code: FailureCode.rideUnavailable),
        );
      }
      return Left(Failure(code: FailureCode.rideAcceptFailed));
    } catch (e) {
      debugPrint('IncomingRequestDebug | Error inesperado en acceptRide: $e');
      return Left(Failure(code: FailureCode.rideAcceptFailed));
    }
  }
}
