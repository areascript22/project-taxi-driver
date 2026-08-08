part of 'session_bloc.dart';

@immutable
sealed class SessionState {}

final class SessionUnknown extends SessionState {}

final class SessionAuthenticated extends SessionState {
  final UserEntity user;
  // Viaje en curso del conductor (asignado/llegó/en camino), si lo hay --
  // null significa que no hay viaje activo. Se resuelve al chequear la
  // sesión para decidir si hay que resumir TripScreen en vez de ir a
  // IncomingRequestScreen.
  final IncomingRequestEntity? activeTrip;

  SessionAuthenticated({required this.user, this.activeTrip});
}

final class SessionUnauthenticated extends SessionState {}
