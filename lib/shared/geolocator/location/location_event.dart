part of 'location_bloc.dart';

@immutable
sealed class LocationEvent {}

// Verifica el permiso actual sin disparar el diálogo nativo del SO.
// Se usa al volver del background para refrescar el estado sin ser intrusivo.
class CheckLocationPermissionEvent extends LocationEvent {}

// Verifica y, si aplica, dispara el diálogo nativo para pedir el permiso.
class CheckAndRequestPermissionEvent extends LocationEvent {}

class OpenAppSettingsEvent extends LocationEvent {}
