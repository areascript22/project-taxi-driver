import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../driver_profile/domain/entity/driver_entity.dart';
import '../../../driver_profile/domain/entity/vehicle_entity.dart';
import '../../../driver_profile/domain/repository/driver_profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final DriverProfileRepository driverProfileRepository;

  ProfileBloc({required this.driverProfileRepository})
    : super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final driverResult = await driverProfileRepository.getDriver(
      driverId: event.driverId,
    );

    final driver = driverResult.fold((failure) => null, (driver) => driver);
    if (driver == null) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo cargar tu información',
        ),
      );
      return;
    }

    VehicleEntity? vehicle;
    if (driver.vehicleId.isNotEmpty) {
      final vehicleResult = await driverProfileRepository.getVehicle(
        vehicleId: driver.vehicleId,
      );
      vehicle = vehicleResult.fold((failure) => null, (vehicle) => vehicle);
    }

    emit(state.copyWith(isLoading: false, driver: driver, vehicle: vehicle));
  }
}
