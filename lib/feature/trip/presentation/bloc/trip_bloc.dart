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
    on<DriverArrivedRequested>(_onDriverArrivedRequested);
    on<CompleteTripRequested>(_onCompleteTripRequested);
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
    emit(state.copyWith(status: data.status));
    if (data.status == 'cancelled') {
      emit(state.copyWith(isCancelled: true, cancelledBy: data.cancelledBy));
      // Cubre ambos lados: si canceló el pasajero, este es el único aviso
      // que recibimos (llega por Firebase, no por un resultado local); si
      // canceló el conductor, esto llega como eco de su propia cancelación.
      // En cualquier caso, ya no tiene sentido seguir reportando ubicación
      // para un viaje cancelado -- no hay que esperar a que el conductor
      // cierre el diálogo o salga de la pantalla.
      driverForegroundService.stopTracking();
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
    // Solo se detiene el TRACKING de este viaje -- el servicio (y el toggle
    // "online" del conductor) deben seguir corriendo tras salir de esta
    // pantalla, cubriendo cualquier forma de abandonarla sin dejar el
    // foreground service reportando ubicación de un viaje que ya no existe.
    await driverForegroundService.stopTracking();
  }

  Future<void> _onDriverArrivedRequested(
    DriverArrivedRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(isMarkingArrived: true, errorMessage: null));

    final result = await repository.markDriverArrived(
      passengerId: event.passengerId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isMarkingArrived: false, errorMessage: failure.message),
      ),
      // El stream de watchTrip ya recibirá status == driverArrived.
      (_) => emit(state.copyWith(isMarkingArrived: false)),
    );
  }

  Future<void> _onCompleteTripRequested(
    CompleteTripRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(isCompleting: true, errorMessage: null));

    final result = await repository.completeTrip(
      passengerId: event.passengerId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(isCompleting: false, errorMessage: failure.message),
      ),
      (_) {
        driverForegroundService.stopTracking();
        emit(state.copyWith(isCompleting: false, isCompleted: true));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
