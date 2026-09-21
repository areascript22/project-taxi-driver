import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/chat_message_entity.dart';

abstract class ChatRepository {
  // Sin Either, igual que TripRepository.watchTrip / RideTrackingRepository
  // .watchRideTrack: es un stream de actualizaciones en vivo (Firestore),
  // no una operación puntual que pueda fallar de una sola vez.
  Stream<List<ChatMessageEntity>> watchMessages({required String rideId});

  // No recibe rideId: el backend lo resuelve del nodo activo del pasajero
  // (mismo patrón que cancelRide/completeTrip), así que solo hace falta
  // identificar la carrera por su pasajero.
  Future<Either<Failure, Unit>> sendMessage({
    required String passengerId,
    required String text,
  });
}
