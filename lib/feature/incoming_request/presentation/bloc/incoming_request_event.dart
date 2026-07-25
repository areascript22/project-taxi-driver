part of 'incoming_request_bloc.dart';

@immutable
sealed class IncomingRequestEvent {}

final class StartListeningRequests extends IncomingRequestEvent {}

final class StopListeningRequests extends IncomingRequestEvent {}

// Eventos internos que el Bloc dispara al reaccionar a los Streams
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
