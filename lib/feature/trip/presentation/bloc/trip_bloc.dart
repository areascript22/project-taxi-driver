import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../../shared/foreground_location/service/driver_foreground_service.dart';
import '../../domain/entity/trip_status_entity.dart';
import '../../domain/repository/trip_repository.dart';

part 'trip_event.dart';
part 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository repository;
  final DriverForegroundService driverForegroundService;
  StreamSubscription<TripStatusEntity>? _subscription;

  TripBloc({required this.repository, required this.driverForegroundService})
    : super(const TripState()) {
    on<StartWatchingTrip>(_onStart);
    on< _TripStatusUpdated>(_onTripStatusUpdated);
    on<CancelTripRequested>(_onCancelRequested);
    on<StopWatchingTrip>(_onStop);
  }

  void _onStart(StartWatchingTrip event, Emitter<TripState> emit) {
    _subscription?.cancel();
    _subscription = repository
        .watchTrip(passengerId: event.passengerId)
        .listen((data) => add(_TripStatusUpdated(data)));

    // El viaje ya fue aceptado (es el único momento en que se llega a esta
    // pantalla) -- arranca el reporte de ubicación del conductor para este
    // pasajero.
    driverForegroundService.start(passengerId: event.passengerId);
  }

  void _onTripStatusUpdated(
    _TripStatusUpdated event,
    Emitter<TripState> emit,
  ) {
    final data = event.data;
    if (data.status == 'cancelled') {
      emit(state.copyWith(isCancelled: true, cancelledBy: data.cancelledBy));
      driverForegroundService.stop();
    }
  }

  Future<void> _onCancelRequested(
    CancelTripRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(isCancelling: true, errorMessage: null));

    await Future.delayed(const Duration(seconds: 2));

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
    // Por seguridad además de la parada en _onTripStatusUpdated: cubre
    // cualquier otra forma de salir de la pantalla de viaje sin dejar el
    // foreground service reportando ubicación de un viaje que ya no existe.
    await driverForegroundService.stop();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
