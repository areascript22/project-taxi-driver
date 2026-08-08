part of 'trip_bloc.dart';

@immutable
class TripState {
  final bool isCancelling;
  final bool isCancelled;
  // Quién canceló el viaje ('passenger' | 'driver'), solo relevante cuando
  // isCancelled == true.
  final String? cancelledBy;
  final String? errorMessage;
  // Status crudo actual del viaje ('driverAssigned' | 'driverArrived' |
  // 'tripStarted' | 'tripCompleted' | 'cancelled'), tal como llega de
  // Firebase -- controla qué botones se muestran en TripScreen.
  final String status;
  final bool isMarkingArrived;
  final bool isCompleting;
  final bool isCompleted;

  const TripState({
    this.isCancelling = false,
    this.isCancelled = false,
    this.cancelledBy,
    this.errorMessage,
    this.status = '',
    this.isMarkingArrived = false,
    this.isCompleting = false,
    this.isCompleted = false,
  });

  TripState copyWith({
    bool? isCancelling,
    bool? isCancelled,
    String? cancelledBy,
    String? errorMessage,
    String? status,
    bool? isMarkingArrived,
    bool? isCompleting,
    bool? isCompleted,
  }) {
    return TripState(
      isCancelling: isCancelling ?? this.isCancelling,
      isCancelled: isCancelled ?? this.isCancelled,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      // Siempre explícito: pasar null limpia el error anterior.
      errorMessage: errorMessage,
      status: status ?? this.status,
      isMarkingArrived: isMarkingArrived ?? this.isMarkingArrived,
      isCompleting: isCompleting ?? this.isCompleting,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
