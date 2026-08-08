part of 'incoming_request_bloc.dart';

@immutable
sealed class IncomingRequestEvent {}

final class StartListeningRequests extends IncomingRequestEvent {}

final class StopListeningRequests extends IncomingRequestEvent {}

// Nuevo evento para aceptar la carrera
final class AcceptRideRequested extends IncomingRequestEvent {
  final IncomingRequestEntity request;
  final UserEntity driverEntity;
  final UserLocation driverLocation;

  AcceptRideRequested({
    required this.request,
    required this.driverEntity,
    required this.driverLocation,
  });
}

final class _RequestAdded extends IncomingRequestEvent {
  final IncomingRequestEntity request;

  _RequestAdded(this.request);
}

final class _RequestChanged extends IncomingRequestEvent {
  final IncomingRequestEntity request;

  _RequestChanged(this.request);
}

final class _RequestRemoved extends IncomingRequestEvent {
  final String rideId;

  _RequestRemoved(this.rideId);
}
