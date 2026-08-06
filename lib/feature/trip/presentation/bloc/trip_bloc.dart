import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../domain/entity/trip_status_entity.dart';
import '../../domain/repository/trip_repository.dart';

part 'trip_event.dart';
part 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository repository;
  StreamSubscription<TripStatusEntity>? _subscription;

  TripBloc({required this.repository}) : super(const TripState()) {
    on<StartWatchingTrip>(_onStart);
    on<_TripStatusUpdated>(_onTripStatusUpdated);
    on<CancelTripRequested>(_onCancelRequested);
    on<StopWatchingTrip>(_onStop);
  }

  void _onStart(StartWatchingTrip event, Emitter<TripState> emit) {
    _subscription?.cancel();
    _subscription = repository
        .watchTrip(passengerId: event.passengerId)
        .listen((data) => add(_TripStatusUpdated(data)));
  }

  void _onTripStatusUpdated(
    _TripStatusUpdated event,
    Emitter<TripState> emit,
  ) {
    final data = event.data;
    if (data.status == 'cancelled') {
      emit(state.copyWith(isCancelled: true, cancelledBy: data.cancelledBy));
    }
  }

  Future<void> _onCancelRequested(
    CancelTripRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(isCancelling: true, errorMessage: null));

    final result = await repository.cancelRide(passengerId: event.passengerId);

    result.fold(
      (failure) => emit(
        state.copyWith(isCancelling: false, errorMessage: failure.message),
      ),
      // El stream de watchTrip ya recibirá status == cancelled.
      (_) => emit(state.copyWith(isCancelling: false)),
    );
  }

  Future<void> _onStop(StopWatchingTrip event, Emitter<TripState> emit) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
