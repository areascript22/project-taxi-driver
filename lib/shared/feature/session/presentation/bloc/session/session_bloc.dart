import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:driver_app/core/l10n/app_language.dart';
import 'package:driver_app/feature/driver_profile/domain/entity/driver_entity.dart';
import 'package:driver_app/feature/driver_profile/domain/repository/driver_profile_repository.dart';
import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/feature/trip/domain/repository/trip_repository.dart';
import 'package:driver_app/shared/feature/settings/domain/repository/settings_repository.dart';
import 'package:flutter/material.dart';
import '../../../../../domain/entity/user_entity.dart';
import '../../../../../domain/repository/session_repository.dart';
import '../../../../../notifications/service/push_notifications_service.dart';

part 'session_event.dart';
part 'session_state.dart';


class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final SessionRepository sessionRepository;
  final TripRepository tripRepository;
  final DriverProfileRepository driverProfileRepository;
  final PushNotificationsService pushNotificationsService;
  final SettingsRepository settingsRepository;

  StreamSubscription<String>? _tokenRefreshSub;

  SessionBloc({
    required this.sessionRepository,
    required this.tripRepository,
    required this.driverProfileRepository,
    required this.pushNotificationsService,
    required this.settingsRepository,
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
    if (driverResult.isLeft()) {
      emit(SessionCheckFailed(user: user));
      return;
    }

    final DriverEntity? driver = driverResult.fold(
      (_) => null,
      (value) => value,
    );
    if (driver == null) {
      emit(SessionOnboardingRequired(user: user));
      return;
    }

    // Se chequea ANTES de armar SessionAuthenticated: un conductor bloqueado
    // o no aprobado no debe llegar a ninguna pantalla autenticada (Incoming
    // Requests, perfil, admin, etc.), no solo a la de "ir online".
    if (driver.isBlocked) {
      emit(SessionBlocked(user: user, blockReason: driver.blockReason));
      return;
    }
    if (driver.approvalStatus != 'approved') {
      emit(
        SessionPendingApproval(
          user: user,
          approvalStatus: driver.approvalStatus,
          rejectionReason: driver.rejectionReason,
        ),
      );
      return;
    }

    final activeTripResult = await tripRepository.findActiveTripForDriver();
    final activeTrip = activeTripResult.fold((_) => null, (trip) => trip);

    emit(SessionAuthenticated(user: user, activeTrip: activeTrip, role: driver.role));

    unawaited(_registerPushToken(driverId: user.id));
  }

  // Fire-and-forget: si falla, el conductor simplemente no recibirá push
  // hasta el siguiente chequeo de sesión -- no debe bloquear ni afectar el
  // flujo de autenticación.
  Future<void> _registerPushToken({required String driverId}) async {
    final tokenResult = await pushNotificationsService.getToken();
    final token = tokenResult.fold((_) => null, (token) => token);
    if (token != null) {
      await driverProfileRepository.updateFcmToken(
        driverId: driverId,
        token: token,
        language: await _resolvePushLanguage(),
      );
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = pushNotificationsService.onTokenRefresh.listen((
      newToken,
    ) async {
      driverProfileRepository.updateFcmToken(
        driverId: driverId,
        token: newToken,
        // Se resuelve de nuevo (y no se reusa el de arriba) porque el refresh
        // puede llegar mucho después, con el idioma ya cambiado en Ajustes.
        language: await _resolvePushLanguage(),
      );
    });
  }

  // Idioma en el que el backend debe armarle los push a ESTE conductor.
  // Se guarda ya resuelto ('es'/'en'): el server no puede resolver "seguir al
  // dispositivo". Si la lectura falla se asume el default, que es justo lo
  // que el server usa cuando el campo no está.
  Future<String> _resolvePushLanguage() async {
    final result = await settingsRepository.getLanguage();
    final preference = result.fold((_) => AppLanguage.system, (value) => value);

    return resolveSystemAppLocale(preference: preference).languageCode;
  }

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    return super.close();
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
