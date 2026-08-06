part of 'incoming_request_bloc.dart';

@immutable
sealed class IncomingRequestState {}

final class IncomingRequestInitial extends IncomingRequestState {}

final class IncomingRequestLoaded extends IncomingRequestState {
  final List<IncomingRequestEntity> requests;

  IncomingRequestLoaded({required this.requests});
}

// Nuevos estados para la acción de aceptar
final class AcceptRideLoading extends IncomingRequestState {}

final class AcceptRideSuccess extends IncomingRequestState {

  AcceptRideSuccess();
}

final class AcceptRideError extends IncomingRequestState {
  final String message;

  AcceptRideError({required this.message});
}
