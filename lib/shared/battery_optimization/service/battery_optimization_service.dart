import 'package:dartz/dartz.dart';
import '../../../core/error/errors.dart';

// Controla el permiso "ignorar optimización de batería" (Android). Sin este
// permiso, Android (sobre todo OEMs como Xiaomi/Huawei/Samsung) puede matar
// el foreground service de ubicación en cuanto el conductor cierra la app,
// perdiendo el tracking de un viaje en curso.
abstract class BatteryOptimizationService {
  Future<Either<Failure, bool>> isIgnoringBatteryOptimizations();

  // Dispara el diálogo NATIVO de Android para pedir el permiso. El usuario
  // puede rechazarlo -- no hay forma de forzar la aceptación a nivel de
  // sistema, así que el `bool` devuelto puede venir en `false`.
  Future<Either<Failure, bool>> requestIgnoreBatteryOptimizations();

  // Fallback si el diálogo nativo sigue siendo rechazado: lleva al usuario a
  // los ajustes de la app para que lo active manualmente.
  Future<Either<Failure, void>> openAppSettings();
}
