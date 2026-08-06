part of 'incoming_request_bloc.dart';

enum AcceptRideStatus { idle, loading, success, error }

@immutable
sealed class IncomingRequestState {}

final class IncomingRequestInitial extends IncomingRequestState {}

final class IncomingRequestLoaded extends IncomingRequestState {
  final List<IncomingRequestEntity> requests;
  final AcceptRideStatus acceptStatus;
  // Solicitud que se está aceptando (o que se acaba de aceptar/fallar).
  // Se guarda la entidad completa -y no solo el rideId- porque al aceptar
  // una carrera esta desaparece de `requests` (deja de matchear el query de
  // Firebase `status == pending`) antes de que la UI pueda navegar con sus datos.
  final IncomingRequestEntity? processingRequest;
  final String? acceptErrorMessage;

  IncomingRequestLoaded({
    required this.requests,
    this.acceptStatus = AcceptRideStatus.idle,
    this.processingRequest,
    this.acceptErrorMessage,
  });

  IncomingRequestLoaded copyWith({
    List<IncomingRequestEntity>? requests,
    AcceptRideStatus? acceptStatus,
    IncomingRequestEntity? processingRequest,
    String? acceptErrorMessage,
  }) {
    return IncomingRequestLoaded(
      requests: requests ?? this.requests,
      acceptStatus: acceptStatus ?? this.acceptStatus,
      processingRequest: processingRequest ?? this.processingRequest,
      acceptErrorMessage: acceptErrorMessage ?? this.acceptErrorMessage,
    );
  }
}
