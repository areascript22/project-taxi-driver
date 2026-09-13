part of 'foreground_service_bloc.dart';

@immutable
sealed class ForegroundServiceEvent {}

// Consulta el estado real del servicio (se dispara al entrar a la pantalla).
class ForegroundServiceStatusRequested extends ForegroundServiceEvent {}

// El usuario tocó el switch.
class ForegroundServiceToggled extends ForegroundServiceEvent {}

// El usuario aceptó el diálogo explicativo propio: dispara el diálogo
// NATIVO de Android para pedir "ignorar optimización de batería". También
// se usa como "Reintentar" desde el banner de bloqueo.
class BatteryOptimizationPermissionRequested extends ForegroundServiceEvent {}

// El usuario cerró/rechazó el diálogo explicativo propio sin llegar a pedir
// el permiso nativo.
class BatteryOptimizationPromptDismissed extends ForegroundServiceEvent {}

// El usuario tocó "Abrir ajustes" en el banner de bloqueo (fallback cuando
// el diálogo nativo sigue siendo rechazado).
class BatteryOptimizationSettingsOpened extends ForegroundServiceEvent {}

// Re-chequeo SILENCIOSO (sin diálogo) al volver del background. Necesario
// porque en varios OEMs (MIUI, etc.) el diálogo nativo de
// "ignorar optimización de batería" redirige a su propia pantalla de
// Ajustes -- el Future de request() se resuelve como "denegado" en cuanto
// ocurre esa redirección, no cuando el usuario termina de interactuar con
// esa pantalla y regresa. Sin este recheck, el toggle quedaría bloqueado
// aunque el usuario sí haya activado "Sin restricciones".
class BatteryOptimizationStatusRechecked extends ForegroundServiceEvent {}
