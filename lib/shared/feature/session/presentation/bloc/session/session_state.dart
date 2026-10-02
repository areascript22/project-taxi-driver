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

// El conductor existe y tiene approvalStatus == 'approved', pero un admin lo
// bloqueó (ver DriverAdminService.updateBlockStatus en el server). Se chequea
// ANTES de emitir SessionAuthenticated -- así ninguna pantalla autenticada
// (Incoming Requests, perfil, etc.) es alcanzable mientras la cuenta esté
// bloqueada, no solo la pantalla de "ir online".
//
// Solo expone los campos primitivos que la UI necesita (igual que `role` en
// SessionAuthenticated) en vez de todo el DriverEntity, para no acoplar a
// quien escuche SessionState con el dominio del feature driver_profile.
final class SessionBlocked extends SessionState {
  final UserEntity user;
  final String? blockReason;

  SessionBlocked({required this.user, this.blockReason});
}

// El conductor existe pero su approvalStatus todavía no es 'approved'
// ('pending' recién registrado, o 'rejected' por un admin). Mismo motivo que
// SessionBlocked: se corta acá, antes de llegar a ninguna pantalla
// autenticada.
final class SessionPendingApproval extends SessionState {
  final UserEntity user;
  // 'pending' | 'rejected'
  final String approvalStatus;
  final String? rejectionReason;

  SessionPendingApproval({
    required this.user,
    required this.approvalStatus,
    this.rejectionReason,
  });
}
