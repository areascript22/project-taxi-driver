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
  final FailureCode? errorCode;
  final LocationProcess locationProcess;

  const LocationState({
    this.permissionStatus,
    this.errorCode,
    this.locationProcess = LocationProcess.initial,
  });

  bool get isGranted =>
      permissionStatus == LocationPermission.always ||
      permissionStatus == LocationPermission.whileInUse;

  bool get isPermanentlyDenied =>
      permissionStatus == LocationPermission.deniedForever;

  LocationState copyWith({
    LocationPermission? permissionStatus,
    FailureCode? errorCode,
    LocationProcess? locationProcess,
    bool clearError = false,
  }) {
    return LocationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      locationProcess: locationProcess ?? this.locationProcess,
    );
  }
}
