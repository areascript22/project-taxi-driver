import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/domain/entity/user_location.dart';
import '../../domain/entity/incoming_request_entity.dart';
import '../../domain/repository/incoming_request_repository.dart';
// Importa tus entidades y repositorio

part 'incoming_request_event.dart';

part 'incoming_request_state.dart';

class IncomingRequestBloc
    extends Bloc<IncomingRequestEvent, IncomingRequestState> {
  final IncomingRequestRepository repository;

  StreamSubscription? _addedSub;
  StreamSubscription? _changedSub;
  StreamSubscription? _removedSub;

  IncomingRequestBloc({required this.repository})
    : super(IncomingRequestInitial()) {
    on<StartListeningRequests>(_onStartListening);
    on<StopListeningRequests>(_onStopListening);
    on<_RequestAdded>(_onRequestAdded);
    on<_RequestChanged>(_onRequestChanged);
    on<_RequestRemoved>(_onRequestRemoved);
    on<AcceptRideRequested>(_onAcceptRideRequested);
  }

  void _onStartListening(
    StartListeningRequests event,
    Emitter<IncomingRequestState> emit,
  ) {
    // Iniciamos el estado con una lista vacía
    emit(IncomingRequestLoaded(requests: []));

    // Conectamos los streams de Firebase a nuestros eventos del Bloc
    _addedSub ??= repository.onRequestAdded.listen(
      (req) => add(_RequestAdded(req)),
    );
    _changedSub ??= repository.onRequestChanged.listen(
      (req) => add(_RequestChanged(req)),
    );
    _removedSub ??= repository.onRequestRemoved.listen(
      (id) => add(_RequestRemoved(id)),
    );
  }

  void _onRequestAdded(
    _RequestAdded event,
    Emitter<IncomingRequestState> emit,
  ) {
    if (state is IncomingRequestLoaded) {
      final currentRequests = (state as IncomingRequestLoaded).requests;

      // Evitamos duplicados por si acaso
      if (currentRequests.any((r) => r.rideId == event.request.rideId)) return;

      final updatedList = List<IncomingRequestEntity>.from(currentRequests)
        ..insert(0, event.request); // Lo agregamos al inicio de la lista

      emit((state as IncomingRequestLoaded).copyWith(requests: updatedList));
    }
  }

  void _onRequestChanged(
    _RequestChanged event,
    Emitter<IncomingRequestState> emit,
  ) {
    if (state is IncomingRequestLoaded) {
      final currentRequests = (state as IncomingRequestLoaded).requests;

      final updatedList =
          currentRequests.map((req) {
            return req.rideId == event.request.rideId ? event.request : req;
          }).toList();

      emit((state as IncomingRequestLoaded).copyWith(requests: updatedList));
    }
  }

  void _onRequestRemoved(
    _RequestRemoved event,
    Emitter<IncomingRequestState> emit,
  ) {
    if (state is IncomingRequestLoaded) {
      final currentRequests = (state as IncomingRequestLoaded).requests;

      final updatedList =
          currentRequests.where((req) => req.rideId != event.rideId).toList();

      emit((state as IncomingRequestLoaded).copyWith(requests: updatedList));
    }
  }

  void _onStopListening(
    StopListeningRequests event,
    Emitter<IncomingRequestState> emit,
  ) {
    _addedSub?.cancel();
    _changedSub?.cancel();
    _removedSub?.cancel();
    _addedSub = null;
    _changedSub = null;
    _removedSub = null;
  }

  Future<void> _onAcceptRideRequested(
    AcceptRideRequested event,
    Emitter<IncomingRequestState> emit,
  ) async {
    final current = state;
    if (current is! IncomingRequestLoaded) return;

    emit(
      current.copyWith(
        acceptStatus: AcceptRideStatus.loading,
        processingRequest: event.request,
      ),
    );

    final result = await repository.acceptRide(
      passengerId: event.request.userId,
      driverEntity: event.driverEntity,
      driverLocation: event.driverLocation,
    );

    // La lista puede haber cambiado mientras esperábamos la transacción
    // (ej: onRequestRemoved ya sacó la solicitud aceptada), así que partimos
    // siempre del estado más reciente en vez del snapshot inicial.
    final latest = state;
    if (latest is! IncomingRequestLoaded) return;

    result.fold(
      (failure) {
        emit(
          latest.copyWith(
            acceptStatus: AcceptRideStatus.error,
            processingRequest: event.request,
            acceptErrorMessage: failure.message,
          ),
        );
      },
      (_) {
        emit(
          latest.copyWith(
            acceptStatus: AcceptRideStatus.success,
            processingRequest: event.request,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _addedSub?.cancel();
    _changedSub?.cancel();
    _removedSub?.cancel();
    return super.close();
  }
}
