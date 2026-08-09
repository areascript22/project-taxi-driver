import 'package:bloc/bloc.dart';
import 'package:driver_app/feature/driver_profile/domain/repository/driver_profile_repository.dart';
import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/feature/trip/domain/repository/trip_repository.dart';
import 'package:flutter/material.dart';
import '../../../../../domain/entity/user_entity.dart';
import '../../../../../domain/repository/session_repository.dart';

part 'session_event.dart';
part 'session_state.dart';


class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository sessionRepository;
  final TripRepository tripRepository;
  final DriverProfileRepository driverProfileRepository;

  SessionBloc({
    required this.sessionRepository,
    required this.tripRepository,
    required this.driverProfileRepository,
  }) : super(SessionUnknown()) {
    on<SessionCheckRequested>(_onCheckRequested);
    on<SessionLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    SessionCheckRequested event,
    Emitter<SessionState> emit,
  ) async {
    final result = await sessionRepository.isUserAuthenticated();

    final user = result.fold((failure) => null, (user) => user);
    if (user == null) {
      emit(SessionUnauthenticated());
      return;
    }

    final driverResult = await driverProfileRepository.getDriver(
      driverId: user.id,
    );
    final driver = driverResult.fold((_) => null, (driver) => driver);
    if (driver == null) {
      emit(SessionOnboardingRequired(user: user));
      return;
    }

    final activeTripResult = await tripRepository.findActiveTripForDriver(
      driverId: user.id,
    );
    final activeTrip = activeTripResult.fold((_) => null, (trip) => trip);

    emit(SessionAuthenticated(user: user, activeTrip: activeTrip));
  }

  Future<void> _onLogoutRequested(SessionLogoutRequested event,
      Emitter<SessionState> emit,) async {
    final response = await sessionRepository.signOut();
    response.fold(
            (failure) => emit(state),
            (unit) =>
        emit(SessionUnauthenticated()));
  }
}
