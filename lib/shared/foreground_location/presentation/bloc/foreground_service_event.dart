part of 'foreground_service_bloc.dart';

@immutable
sealed class ForegroundServiceEvent {}

// Consulta el estado real del servicio (se dispara al entrar a la pantalla).
class ForegroundServiceStatusRequested extends ForegroundServiceEvent {}

// El usuario tocó el switch.
class ForegroundServiceToggled extends ForegroundServiceEvent {}
