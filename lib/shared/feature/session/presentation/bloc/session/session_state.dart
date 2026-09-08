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
  // 'driver' | 'admin' | 'superuser' -- controla la visibilidad del tab
  // Admin en el bottom nav bar.
  final String role;

  SessionAuthenticated({
    required this.user,
    this.activeTrip,
    this.role = 'driver',
  });
}

final class SessionUnauthenticated extends SessionState {}

// El usuario ya se autenticó con Google pero todavía no tiene datos de
// conductor guardados en Firestore -- debe completar el registro
// (datos personales + vehículo) antes de continuar.
final class SessionOnboardingRequired extends SessionState {
  final UserEntity user;

  SessionOnboardingRequired({required this.user});
}

// El usuario está autenticado pero no se pudo verificar si tiene datos de
// conductor guardados (error de red, permisos, etc.) -- distinto de
// SessionOnboardingRequired: acá NO sabemos si el conductor ya existe, así
// que no se debe mandar a re-registrar, sino permitir reintentar.
final class SessionCheckFailed extends SessionState {
  final UserEntity user;

  SessionCheckFailed({required this.user});
}
