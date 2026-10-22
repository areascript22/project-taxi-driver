part of 'profile_bloc.dart';

@immutable
class ProfileState {
  final bool isLoading;
  final DriverEntity? driver;
  final VehicleEntity? vehicle;
  final FailureCode? errorCode;

  const ProfileState({
    this.isLoading = false,
    this.driver,
    this.vehicle,
    this.errorCode,
  });

  ProfileState copyWith({
    bool? isLoading,
    DriverEntity? driver,
    VehicleEntity? vehicle,
    FailureCode? errorCode,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      errorCode: errorCode,
    );
  }
}
