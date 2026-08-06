part of 'trip_bloc.dart';

@immutable
class TripState {
  final bool isCancelling;
  final bool isCancelled;
  // Quién canceló el viaje ('passenger' | 'driver'), solo relevante cuando
  // isCancelled == true.
  final String? cancelledBy;
  final String? errorMessage;

  const TripState({
    this.isCancelling = false,
    this.isCancelled = false,
    this.cancelledBy,
    this.errorMessage,
  });

  TripState copyWith({
    bool? isCancelling,
    bool? isCancelled,
    String? cancelledBy,
    String? errorMessage,
  }) {
    return TripState(
      isCancelling: isCancelling ?? this.isCancelling,
      isCancelled: isCancelled ?? this.isCancelled,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      // Siempre explícito: pasar null limpia el error anterior.
      errorMessage: errorMessage,
    );
  }
}
