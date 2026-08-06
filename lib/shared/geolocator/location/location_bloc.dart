import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/shared/geolocator/service/geolocator/geolocator_service.dart';

part 'location_event.dart';

part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GeolocatorService locationService;

  LocationBloc({required this.locationService}) : super(const LocationState()) {
    on<CheckLocationPermissionEvent>(_onCheckPermission);
    on<CheckAndRequestPermissionEvent>(_onCheckAndRequestPermission);
    on<OpenAppSettingsEvent>(_onOpenAppSettings);
  }

  Future<void> _onCheckPermission(
    CheckLocationPermissionEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(locationProcess: LocationProcess.checkingPermissions));

    final result = await locationService.checkPermission();

    result.fold(
      (failure) => emit(
        state.copyWith(
          locationProcess: LocationProcess.permissionsError,
          errorMessage: failure.message,
        ),
      ),
      (permission) => emit(
        state.copyWith(
          locationProcess: LocationProcess.permissionsReady,
          permissionStatus: permission,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onCheckAndRequestPermission(
    CheckAndRequestPermissionEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(locationProcess: LocationProcess.checkingPermissions));

    final result = await locationService.checkAndRequestPermission();

    result.fold(
      (failure) => emit(
        state.copyWith(
          locationProcess: LocationProcess.permissionsError,
          errorMessage: failure.message,
        ),
      ),
      (permission) => emit(
        state.copyWith(
          locationProcess: LocationProcess.permissionsReady,
          permissionStatus: permission,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onOpenAppSettings(
    OpenAppSettingsEvent event,
    Emitter<LocationState> emit,
  ) async {
    await locationService.openAppSettings();
  }
}
