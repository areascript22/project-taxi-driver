part of 'location_bloc.dart';

enum LocationProcess {
  initial,
  checkingPermissions,
  permissionsReady,
  permissionsError,
}

@immutable
class LocationState {
  final LocationPermission? permissionStatus;
  final String? errorMessage;
  final LocationProcess locationProcess;

  const LocationState({
    this.permissionStatus,
    this.errorMessage,
    this.locationProcess = LocationProcess.initial,
  });

  bool get isGranted =>
      permissionStatus == LocationPermission.always ||
      permissionStatus == LocationPermission.whileInUse;

  bool get isPermanentlyDenied =>
      permissionStatus == LocationPermission.deniedForever;

  LocationState copyWith({
    LocationPermission? permissionStatus,
    String? errorMessage,
    LocationProcess? locationProcess,
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      locationProcess: locationProcess ?? this.locationProcess,
    );
  }
}
