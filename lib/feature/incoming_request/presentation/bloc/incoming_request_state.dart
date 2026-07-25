part of 'incoming_request_bloc.dart';

@immutable
sealed class IncomingRequestState {}

final class IncomingRequestInitial extends IncomingRequestState {}

final class IncomingRequestLoaded extends IncomingRequestState {
  final List<IncomingRequestEntity> requests;

  IncomingRequestLoaded({required this.requests});
}
