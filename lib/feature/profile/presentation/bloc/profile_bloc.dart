import 'package:bloc/bloc.dart';
import 'package:driver_app/core/error/errors.dart';
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
    emit(state.copyWith(isLoading: true, errorCode: null));

    final driverResult = await driverProfileRepository.getDriver(
      driverId: event.driverId,
    );

    final driver = driverResult.fold((failure) => null, (driver) => driver);
    if (driver == null) {
      emit(
        state.copyWith(
          isLoading: false,
          errorCode: FailureCode.profileLoadFailed,
        ),
      );
      return;
    }

    // Se pide siempre: el servidor devuelve el vehiculo de la sesion y
    // DriverModel.toEntity() deja `vehicleId` vacio (ese dato ya no viaja en el
    // conductor). Condicionar la consulta a `driver.vehicleId` dejaba la tarjeta
    // del vehiculo siempre en "No registrado".
    final vehicleResult = await driverProfileRepository.getVehicle(
      vehicleId: driver.vehicleId,
    );
    final VehicleEntity? vehicle = vehicleResult.fold(
      (failure) => null,
      (vehicle) => vehicle,
    );

    emit(state.copyWith(isLoading: false, driver: driver, vehicle: vehicle));
  }
}
