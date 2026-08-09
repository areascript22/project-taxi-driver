part of 'profile_bloc.dart';

@immutable
class ProfileState {
  final bool isLoading;
  final DriverEntity? driver;
  final VehicleEntity? vehicle;
  final String? errorMessage;

  const ProfileState({
    this.isLoading = false,
    this.driver,
    this.vehicle,
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    DriverEntity? driver,
    VehicleEntity? vehicle,
    String? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      errorMessage: errorMessage,
    );
  }
}
